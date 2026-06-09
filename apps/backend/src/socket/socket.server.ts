import { Server } from 'socket.io'
import type { Server as HttpServer } from 'node:http'
import type {
  ServerToClientEvents,
  ClientToServerEvents,
  SocketData,
} from './socket.types.js'
import { verifyAccessToken } from '../modules/auth/session.service.js'
import { registerLobbyHandlers } from '../modules/lobby/lobby.handlers.js'
import { roomManager } from '../modules/rooms/room.manager.js'
import { env } from '../config/env.js'

export type AppIO = Server<ClientToServerEvents, ServerToClientEvents, Record<never, never>, SocketData>

export function createSocketServer(httpServer: HttpServer): AppIO {
  const io: AppIO = new Server(httpServer, {
    cors: {
      origin: env.CORS_ORIGIN,
      methods: ['GET', 'POST'],
    },
  })

  // ── Auth middleware ────────────────────────────────────────────────────────
  // El cliente envía el access token en socket.handshake.auth.token

  io.use((socket, next) => {
    const token = socket.handshake.auth['token'] as string | undefined

    if (!token) {
      return next(new Error('UNAUTHORIZED'))
    }

    try {
      socket.data.session = verifyAccessToken(token)
      next()
    } catch {
      next(new Error('UNAUTHORIZED'))
    }
  })

  // ── Connection ─────────────────────────────────────────────────────────────

  io.on('connection', (socket) => {
    const { session } = socket.data
    console.log(`[socket] + ${session.displayName} (${socket.id})`)

    registerLobbyHandlers(io, socket)

    // ── Disconnect ───────────────────────────────────────────────────────────
    // Marca al jugador como desconectado pero NO lo saca de la sala.
    // El cliente puede reconectarse con el mismo token y retomar su lugar.

    socket.on('disconnect', (reason) => {
      console.log(`[socket] - ${session.displayName} (${socket.id}) — ${reason}`)

      const result = roomManager.markDisconnected(socket.id)

      if (result && result.room.players.size > 0) {
        io.to(result.room.code).emit('lobby:player_left', {
          profileId: result.profileId,
        })
        io.to(result.room.code).emit('lobby:room_state', {
          room: roomManager.toView(result.room),
        })
      }
    })
  })

  return io
}
