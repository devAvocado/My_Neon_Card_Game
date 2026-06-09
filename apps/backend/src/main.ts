import { buildApp } from './app.js'
import { createSocketServer } from './socket/socket.server.js'
import { env } from './config/env.js'

async function bootstrap() {
  const app = await buildApp()

  await app.listen({ port: env.PORT, host: '0.0.0.0' })

  const io = createSocketServer(app.server)

  console.log(`\n🚀 Server listening on port ${env.PORT}`)
  console.log(`🎮 Socket.IO ready`)
  console.log(`🌍 ENV: ${env.NODE_ENV}\n`)

  // ── Graceful shutdown ──────────────────────────────────────────────────────

  const shutdown = async (signal: string) => {
    console.log(`\n⚠️  ${signal} received — shutting down...`)
    io.close()
    await app.close()
    console.log('✅ Server closed.')
    process.exit(0)
  }

  process.on('SIGINT', () => void shutdown('SIGINT'))
  process.on('SIGTERM', () => void shutdown('SIGTERM'))
}

bootstrap().catch((err) => {
  console.error('❌ Fatal error during bootstrap:', err)
  process.exit(1)
})
