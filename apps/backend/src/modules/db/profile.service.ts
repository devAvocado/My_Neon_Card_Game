import { supabase } from '../../lib/supabase.js'

export interface Profile {
  id: string
  username: string
  avatar_key: string
  created_at: string
}

/**
 * Get or create a profile by username + avatarKey.
 * Si el par ya existe, actualiza last_seen_at y lo retorna.
 * Si no existe, lo crea.
 */
export async function getOrCreateProfile(
  username: string,
  avatarKey: string,
): Promise<Profile> {
  const { data, error } = await supabase
    .rpc('rpc_get_or_create_profile', {
      p_username: username,
      p_avatar_key: avatarKey,
    })
    .single()

  if (error) throw new Error(`DB_ERROR: ${error.message}`)
  if (!data) throw new Error('PROFILE_NOT_RETURNED')

  return data as Profile
}

/**
 * Busca avatarKeys usados por un username.
 * Útil para el login UI (sugerir combos previos).
 */
export async function findProfilesByUsername(username: string): Promise<string[]> {
  const { data, error } = await supabase.rpc('rpc_find_profiles_by_username', {
    p_username: username,
  })

  if (error) throw new Error(`DB_ERROR: ${error.message}`)

  return ((data ?? []) as Array<{ avatar_key: string }>).map((row) => row.avatar_key)
}
