import 'dotenv/config'
import { z } from 'zod'

const schema = z.object({
  PORT: z.coerce.number().int().positive().default(3000),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),

  // Supabase
  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),

  // JWT
  JWT_ACCESS_SECRET: z.string().min(32),
  JWT_REFRESH_SECRET: z.string().min(32),
  JWT_ACCESS_EXPIRES_IN: z.string().default('4h'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('7d'),

  // CORS
  CORS_ORIGIN: z.string().default('*'),
})

const result = schema.safeParse(process.env)

if (!result.success) {
  console.error('❌ Variables de entorno inválidas:')
  console.error(result.error.flatten().fieldErrors)
  process.exit(1)
}

export const env = result.data
export type Env = typeof env
