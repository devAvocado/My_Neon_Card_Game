import type { Server, Socket } from 'socket.io'
import type {
  ServerToClientEvents,
  ClientToServerEvents,
  SocketData,
} from '../../socket/socket.types.js'
import { roomManager } from '../rooms/room.manager.js'
import {
  createMatch,
  startMatch,
  addPlayerToMatch,
  createReplay,
} from '../db/match.service.js'

type IO = Server<ClientToServerEvents, ServerToClientEvents, Record<never, never>, SocketData>
type AppSocket = Socket<ClientToServerEvents, ServerToClientEvents, Record<never, never>, SocketData>

export function registerLobbyHandlers(io: IO, socket: AppSocket): void {
  const { session } = socket.data

  // ── CREAR SALA ─────────────────────────────────────────────────────────────

  socket.on('lobby:create_room', async (payload, ack) => {
    try {
      // Si ya está en una sala, salir primero
      roomManager.leaveRoom(socket.id)

      const room = roomManager.createRoom({
        host: {
          profileId: session.profileId,
          socketId: socket.id,
          displayName: session.displayName,
          avatarKey: session.avatarKey,
          isReady: false,
          isConnected: true,
        },
        gamePresetKey: payload.gamePresetKey,
        deckPresetKey: payload.deckPresetKey,
      })

      await socket.join(room.code)

      ack({ ok: true, room: roomManager.toView(room) })
    } catch (err) {
      ack({ ok: false, error: err instanceof Error ? err.message : 'UNKNOWN_ERROR' })
    }
  })

  // ── UNIRSE A SALA ──────────────────────────────────────────────────────────

  socket.on('lobby:join_room', async (payload, ack) => {
    try {
      // Salir de sala actual si aplica
      const left = roomManager.leaveRoom(socket.id)
      if (left) {
        await socket.leave(left.room.code)
        if (left.room.players.size > 0) {
          io.to(left.room.code).emit('lobby:player_left', {
            profileId: left.player.profileId,
          })
        }
      }

      const room = roomManager.joinRoom(payload.roomCode, {
        profileId: session.profileId,
        socketId: socket.id,
        displayName: session.displayName,
        avatarKey: session.avatarKey,
        isReady: false,
        isConnected: true,
      })

      await socket.join(room.code)

      const view = roomManager.toView(room)

      // Notificar a los demás jugadores
      socket.to(room.code).emit('lobby:player_joined', {
        profileId: session.profileId,
        displayName: session.displayName,
        avatarKey: session.avatarKey,
      })

      // Estado completo al que recién entró
      ack({ ok: true, room: view })

      // Estado actualizado a todos
      io.to(room.code).emit('lobby:room_state', { room: view })
    } catch (err) {
      ack({ ok: false, error: err instanceof Error ? err.message : 'UNKNOWN_ERROR' })
    }
  })

  // ── SALIR DE SALA ──────────────────────────────────────────────────────────

  socket.on('lobby:leave_room', async (ack) => {
    try {
      const result = roomManager.leaveRoom(socket.id)

      if (result) {
        await socket.leave(result.room.code)

        if (result.room.players.size > 0) {
          io.to(result.room.code).emit('lobby:player_left', {
            profileId: result.player.profileId,
          })
          io.to(result.room.code).emit('lobby:room_state', {
            room: roomManager.toView(result.room),
          })
        }
      }

      ack({ ok: true })
    } catch {
      ack({ ok: true }) // dejar la sala nunca falla desde la perspectiva del cliente
    }
  })

  // ── READY ──────────────────────────────────────────────────────────────────

  socket.on('lobby:set_ready', (payload, ack) => {
    const room = roomManager.setReady(socket.id, payload.ready)

    if (!room) return ack({ ok: false, error: 'NOT_IN_ROOM' })

    io.to(room.code).emit('lobby:player_ready', {
      profileId: session.profileId,
      ready: payload.ready,
    })

    ack({ ok: true })
  })

  // ── START MATCH ────────────────────────────────────────────────────────────

  socket.on('lobby:start_match', async (ack) => {
    const room = roomManager.getRoomBySocketId(socket.id)

    if (!room) return ack({ ok: false, error: 'NOT_IN_ROOM' })
    if (room.hostProfileId !== session.profileId) return ack({ ok: false, error: 'NOT_HOST' })
    if (room.status !== 'waiting') return ack({ ok: false, error: 'ALREADY_STARTED' })
    if (room.players.size < 2) return ack({ ok: false, error: 'NOT_ENOUGH_PLAYERS' })

    // Todos los non-host deben estar listos
    const allReady = [...room.players.values()]
      .filter((p) => p.profileId !== room.hostProfileId)
      .every((p) => p.isReady)

    if (!allReady) return ack({ ok: false, error: 'PLAYERS_NOT_READY' })

    try {
      const matchId = await createMatch(room.gamePresetKey, room.deckPresetKey)

      await Promise.all(
        [...room.players.values()].map((p) => addPlayerToMatch(matchId, p.profileId)),
      )

      await startMatch(matchId)

      // Seed deterministic — en producción usar crypto.getRandomValues
      const seed = Math.floor(Math.random() * Number.MAX_SAFE_INTEGER)

      const replayId = await createReplay(matchId, seed)

      roomManager.startMatch(room.code, matchId, replayId)

      io.to(room.code).emit('lobby:match_starting', { matchId, seed })

      ack({ ok: true, matchId, seed })
    } catch (err) {
      ack({ ok: false, error: err instanceof Error ? err.message : 'DB_ERROR' })
    }
  })
}
