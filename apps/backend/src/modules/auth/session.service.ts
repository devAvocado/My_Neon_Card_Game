import jwt from 'jsonwebtoken'
import { v4 as uuidv4 } from 'uuid'
import { z } from 'zod'
import { env } from '../../config/env.js'

// ─── Payload del access token ─────────────────────────────────────────────────

export const jwtPayloadSchema = z.object({
  sessionId: z.string().uuid(),
  profileId: z.string().uuid(),
  displayName: z.string(),
  avatarKey: z.string(),
})

export type JWTPayload = z.infer<typeof jwtPayloadSchema>

// ─── Payload mínimo del refresh token ────────────────────────────────────────

const refreshPayloadSchema = z.object({
  sessionId: z.string().uuid(),
  profileId: z.string().uuid(),
})

export type RefreshPayload = z.infer<typeof refreshPayloadSchema>

// ─── Token pair ───────────────────────────────────────────────────────────────

export interface TokenPair {
  accessToken: string
  refreshToken: string
}

/**
 * Genera un par de tokens JWT para un perfil.
 * Cada sesión recibe un sessionId único → permite invalidación individual.
 */
export function createTokenPair(profile: {
  id: string
  username: string
  avatar_key: string
}): TokenPair {
  const sessionId = uuidv4()

  const accessPayload: JWTPayload = {
    sessionId,
    profileId: profile.id,
    displayName: profile.username,
    avatarKey: profile.avatar_key,
  }

  const accessToken = jwt.sign(accessPayload, env.JWT_ACCESS_SECRET, {
    expiresIn: env.JWT_ACCESS_EXPIRES_IN as jwt.SignOptions['expiresIn'],
  })

  const refreshToken = jwt.sign(
    { sessionId, profileId: profile.id } satisfies RefreshPayload,
    env.JWT_REFRESH_SECRET,
    { expiresIn: env.JWT_REFRESH_EXPIRES_IN as jwt.SignOptions['expiresIn'] },
  )

  return { accessToken, refreshToken }
}

/**
 * Verifica y parsea un access token.
 * Lanza si expiró o es inválido.
 */
export function verifyAccessToken(token: string): JWTPayload {
  const raw = jwt.verify(token, env.JWT_ACCESS_SECRET)
  return jwtPayloadSchema.parse(raw)
}

/**
 * Verifica y parsea un refresh token.
 * Lanza si expiró o es inválido.
 */
export function verifyRefreshToken(token: string): RefreshPayload {
  const raw = jwt.verify(token, env.JWT_REFRESH_SECRET)
  return refreshPayloadSchema.parse(raw)
}
