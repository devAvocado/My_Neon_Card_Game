import type { JWTPayload } from '../modules/auth/session.service.js'
import type { RoomView } from '../modules/rooms/room.types.js'

// ─── Ack helper ───────────────────────────────────────────────────────────────

type AckOk<T extends object = object> = { ok: true } & T
type AckErr = { ok: false; error: string }
type Ack<T extends object = object> = AckOk<T> | AckErr

// ─── Client → Server payloads ─────────────────────────────────────────────────

export interface CreateRoomPayload {
  gamePresetKey: string
  deckPresetKey: string
}

export interface JoinRoomPayload {
  roomCode: string
}

export interface SetReadyPayload {
  ready: boolean
}

// ─── Server → Client payloads ─────────────────────────────────────────────────

export interface RoomStatePayload {
  room: RoomView
}

export interface PlayerJoinedPayload {
  profileId: string
  displayName: string
  avatarKey: string
}

export interface PlayerLeftPayload {
  profileId: string
}

export interface PlayerReadyPayload {
  profileId: string
  ready: boolean
}

export interface MatchStartingPayload {
  matchId: string
  seed: number
}

export interface ErrorPayload {
  code: string
  message?: string
}

// ─── Socket.IO typed maps ─────────────────────────────────────────────────────

export interface ServerToClientEvents {
  'lobby:room_state': (data: RoomStatePayload) => void
  'lobby:player_joined': (data: PlayerJoinedPayload) => void
  'lobby:player_left': (data: PlayerLeftPayload) => void
  'lobby:player_ready': (data: PlayerReadyPayload) => void
  'lobby:match_starting': (data: MatchStartingPayload) => void
  error: (data: ErrorPayload) => void
}

export interface ClientToServerEvents {
  'lobby:create_room': (
    payload: CreateRoomPayload,
    ack: (res: Ack<{ room: RoomView }>) => void,
  ) => void

  'lobby:join_room': (
    payload: JoinRoomPayload,
    ack: (res: Ack<{ room: RoomView }>) => void,
  ) => void

  'lobby:leave_room': (
    ack: (res: Ack) => void,
  ) => void

  'lobby:set_ready': (
    payload: SetReadyPayload,
    ack: (res: Ack) => void,
  ) => void

  'lobby:start_match': (
    ack: (res: Ack<{ matchId: string; seed: number }>) => void,
  ) => void
}

/** Datos por socket — seteados por el middleware de auth */
export interface SocketData {
  session: JWTPayload
}
