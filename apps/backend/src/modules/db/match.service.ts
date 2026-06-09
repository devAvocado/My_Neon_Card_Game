import { supabase } from '../../lib/supabase.js'

// ─── Matches ──────────────────────────────────────────────────────────────────

export async function createMatch(
  gamePresetKey: string,
  deckPresetKey: string,
): Promise<string> {
  const { data, error } = await supabase
    .rpc('rpc_create_match', {
      p_game_preset_key: gamePresetKey,
      p_deck_preset_key: deckPresetKey,
    })
    .single()

  if (error) throw new Error(`DB_ERROR: ${error.message}`)
  if (!data) throw new Error('MATCH_NOT_CREATED')

  return (data as { id: string }).id
}

export async function startMatch(matchId: string): Promise<void> {
  const { error } = await supabase.rpc('rpc_start_match', {
    p_match_id: matchId,
  })
  if (error) throw new Error(`DB_ERROR: ${error.message}`)
}

export async function finishMatch(matchId: string): Promise<void> {
  const { error } = await supabase.rpc('rpc_finish_match', {
    p_match_id: matchId,
  })
  if (error) throw new Error(`DB_ERROR: ${error.message}`)
}

export async function addPlayerToMatch(
  matchId: string,
  profileId: string,
): Promise<void> {
  const { error } = await supabase.rpc('rpc_add_player_to_match', {
    p_match_id: matchId,
    p_profile_id: profileId,
  })
  if (error) throw new Error(`DB_ERROR: ${error.message}`)
}

// ─── Replays ──────────────────────────────────────────────────────────────────

export async function createReplay(
  matchId: string,
  initialSeed: number,
): Promise<string> {
  const { data, error } = await supabase
    .rpc('rpc_create_replay', {
      p_match_id: matchId,
      p_initial_seed: initialSeed,
    })
    .single()

  if (error) throw new Error(`DB_ERROR: ${error.message}`)
  if (!data) throw new Error('REPLAY_NOT_CREATED')

  return (data as { id: string }).id
}

export async function appendReplayCommand(
  replayId: string,
  sequenceNumber: number,
  commandJson: Record<string, unknown>,
): Promise<void> {
  const { error } = await supabase.rpc('rpc_append_replay_command', {
    p_replay_id: replayId,
    p_sequence_number: sequenceNumber,
    p_command_json: commandJson,
  })
  if (error) throw new Error(`DB_ERROR: ${error.message}`)
}
