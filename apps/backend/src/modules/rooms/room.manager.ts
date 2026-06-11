import type { Room, RoomPlayer, RoomView } from './room.types.js'
import { generateRoomCode } from './room.codes.js'

const MAX_PLAYERS_PER_ROOM = 6
const MAX_ROOMS = 200

class RoomManager {
  /** code → Room */
  private readonly rooms = new Map<string, Room>()
  /** socketId → roomCode */
  private readonly socketToRoom = new Map<string, string>()

  // ─── Crear sala ─────────────────────────────────────────────────────────────

  createRoom(options: {
    host: RoomPlayer
    gamePresetKey: string
    deckPresetKey: string
  }): Room {
    if (this.rooms.size >= MAX_ROOMS) throw new Error('SERVER_FULL')

    // Generar código único
    let code: string
    do { code = generateRoomCode() } while (this.rooms.has(code))

    const players = new Map<string, RoomPlayer>()
    players.set(options.host.profileId, options.host)

    const room: Room = {
      code,
      hostProfileId: options.host.profileId,
      players,
      status: 'waiting',
      gamePresetKey: options.gamePresetKey,
      deckPresetKey: options.deckPresetKey,
      createdAt: new Date(),
    }

    this.rooms.set(code, room)
    this.socketToRoom.set(options.host.socketId, code)

    return room
  }

  // ─── Unirse a sala ──────────────────────────────────────────────────────────

  joinRoom(code: string, player: RoomPlayer): Room {
    const room = this.rooms.get(code)
    if (!room) throw new Error('ROOM_NOT_FOUND')
    if (room.status !== 'waiting') throw new Error('ROOM_NOT_WAITING')

    // Reconexión: mismo profileId, nuevo socketId
    const existing = room.players.get(player.profileId)
    if (existing) {
      this.socketToRoom.delete(existing.socketId)
      room.players.set(player.profileId, {
        ...existing,
        socketId: player.socketId,
        isConnected: true,
      })
    } else {
      if (room.players.size >= MAX_PLAYERS_PER_ROOM) throw new Error('ROOM_FULL')
      room.players.set(player.profileId, player)
    }

    this.socketToRoom.set(player.socketId, code)
    return room
  }

  // ─── Salir de sala ──────────────────────────────────────────────────────────

  leaveRoom(socketId: string): { room: Room; player: RoomPlayer } | null {
    const code = this.socketToRoom.get(socketId)
    if (!code) return null

    const room = this.rooms.get(code)
    if (!room) return null

    let leavingPlayer: RoomPlayer | undefined
    for (const [profileId, p] of room.players) {
      if (p.socketId === socketId) {
        leavingPlayer = p
        room.players.delete(profileId)
        break
      }
    }

    this.socketToRoom.delete(socketId)
    if (!leavingPlayer) return null

    // Transferir host si es necesario
    if (room.hostProfileId === leavingPlayer.profileId && room.players.size > 0) {
      const next = room.players.values().next().value
      if (next) room.hostProfileId = next.profileId
    }

    // Destruir sala vacía
    if (room.players.size === 0) this.rooms.delete(code)

    return { room, player: leavingPlayer }
  }

  // ─── Desconexión temporal (no abandona la sala) ─────────────────────────────

  markDisconnected(socketId: string): { room: Room; profileId: string } | null {
    const code = this.socketToRoom.get(socketId)
    if (!code) return null

    const room = this.rooms.get(code)
    if (!room) return null

    for (const [profileId, p] of room.players) {
      if (p.socketId === socketId) {
        room.players.set(profileId, { ...p, isConnected: false })
        return { room, profileId }
      }
    }

    return null
  }

  // ─── Ready ──────────────────────────────────────────────────────────────────

  setReady(socketId: string, ready: boolean): Room | null {
    const code = this.socketToRoom.get(socketId)
    if (!code) return null

    const room = this.rooms.get(code)
    if (!room) return null

    for (const [profileId, p] of room.players) {
      if (p.socketId === socketId) {
        room.players.set(profileId, { ...p, isReady: ready })
        return room
      }
    }

    return null
  }

  // ─── Start match ────────────────────────────────────────────────────────────

  startMatch(code: string, matchId: string, replayId: string): Room {
    const room = this.rooms.get(code)
    if (!room) throw new Error('ROOM_NOT_FOUND')

    room.status = 'active'
    room.matchId = matchId
    room.replayId = replayId
    return room
  }

  // ─── Queries ────────────────────────────────────────────────────────────────

  getRoom(code: string): Room | undefined {
    return this.rooms.get(code)
  }

  getRoomBySocketId(socketId: string): Room | undefined {
    const code = this.socketToRoom.get(socketId)
    return code ? this.rooms.get(code) : undefined
  }

  getRoomCodeBySocketId(socketId: string): string | undefined {
    return this.socketToRoom.get(socketId)
  }

  // ─── Serialización ──────────────────────────────────────────────────────────

  toView(room: Room): RoomView {
    return {
      code: room.code,
      hostProfileId: room.hostProfileId,
      status: room.status,
      gamePresetKey: room.gamePresetKey,
      deckPresetKey: room.deckPresetKey,
      createdAt: room.createdAt.toISOString(),
      players: [...room.players.values()].map((p) => ({
        profileId: p.profileId,
        displayName: p.displayName,
        avatarKey: p.avatarKey,
        isReady: p.isReady,
        isConnected: p.isConnected,
      })),
    }
  }
}

/** Singleton — una instancia para todo el proceso */
export const roomManager = new RoomManager()
