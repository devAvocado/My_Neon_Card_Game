import { createClient } from '@supabase/supabase-js'
import { env } from '../config/env.js'

/**
 * Cliente Supabase con service_role key.
 * Bypasa RLS — solo usar server-side.
 * Toda interacción con la DB va por RPCs.
 */
export const supabase = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
})
