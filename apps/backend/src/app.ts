import Fastify from 'fastify'
import cors from '@fastify/cors'
import { z } from 'zod'
import { env } from './config/env.js'
import { getOrCreateProfile, findProfilesByUsername } from './modules/db/profile.service.js'
import { createTokenPair } from './modules/auth/session.service.js'


export async function buildApp() {
  const app = Fastify({
    logger: env.NODE_ENV !== 'test',
  })

  await app.register(cors, { origin: env.CORS_ORIGIN })

  // ── Health ─────────────────────────────────────────────────────────────────

  app.get('/health', async () => ({
    ok: true,
    ts: new Date().toISOString(),
  }))

  // ── POST /auth/login ───────────────────────────────────────────────────────
  // Guest-first: username + avatarKey → JWT pair
  //
  // El cliente debe llamar este endpoint antes de conectarse por socket.
  // Con el accessToken en mano, conecta: io({ auth: { token } })

  const loginBody = z.object({
    username: z.string().min(2).max(24).trim(),
    avatarKey: z.string().min(3).max(32).trim(),
  })

  app.post('/auth/login', async (req, reply) => {
    const parsed = loginBody.safeParse(req.body)

    if (!parsed.success) {
      return reply.status(400).send({
        error: 'VALIDATION_ERROR',
        fields: parsed.error.flatten().fieldErrors,
      })
    }

    try {
      const profile = await getOrCreateProfile(
        parsed.data.username,
        parsed.data.avatarKey,
      )
      const tokens = createTokenPair(profile)

      return reply.send({
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        profile: {
          id: profile.id,
          username: profile.username,
          avatarKey: profile.avatar_key,
        },
      })
    } catch (err) {
      app.log.error(err)
      return reply.status(500).send({ error: 'INTERNAL_ERROR' })
    }
  })

  // ── GET /auth/lookup?username=xxx ──────────────────────────────────────────
  // Retorna los avatarKeys asociados a un username.
  // Útil para mostrar combos previos en el login UI.

  app.get<{ Querystring: { username?: string } }>('/auth/lookup', async (req, reply) => {
    const username = req.query['username']?.trim() ?? ''

    if (username.length < 2) {
      return reply.status(400).send({ error: 'USERNAME_TOO_SHORT' })
    }

    try {
      const avatarKeys = await findProfilesByUsername(username)
      return reply.send({ avatarKeys })
    } catch (err) {
      app.log.error(err)
      return reply.status(500).send({ error: 'INTERNAL_ERROR' })
    }
  })

  return app
}
