// ─── Internos (in-memory) ─────────────────────────────────────────────────────

export type RoomStatus = 'waiting' | 'active' | 'finished'

export interface RoomPlayer {
  profileId: string
  socketId: string
  displayName: string
  avatarKey: string
  isReady: boolean
  isConnected: boolean
}

export interface Room {
  code: string
  hostProfileId: string
  /** Keyed by profileId */
  players: Map<string, RoomPlayer>
  status: RoomStatus
  gamePresetKey: string
  deckPresetKey: string
  /** Seteado al iniciarse la partida */
  matchId?: string
  replayId?: string
  createdAt: Date
}

// ─── Serializables (para emit) ────────────────────────────────────────────────

export interface RoomPlayerView {
  profileId: string
  displayName: string
  avatarKey: string
  isReady: boolean
  isConnected: boolean
}

export interface RoomView {
  code: string
  hostProfileId: string
  status: RoomStatus
  gamePresetKey: string
  deckPresetKey: string
  players: RoomPlayerView[]
  createdAt: string
}
