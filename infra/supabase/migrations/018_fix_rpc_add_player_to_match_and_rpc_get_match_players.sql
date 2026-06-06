-- ============================================================================
-- FIX
-- 018_fix_rpc_add_player_to_match_and_rpc_get_match_players
--
-- Corrige referencias a final_card_count.
-- La columna correcta es deadly_card_count.
-- ============================================================================

create or replace function public.rpc_add_player_to_match(
  p_match_id uuid,
  p_profile_id uuid
)
returns void
language sql
as $$
  insert into public.match_players (
    match_id,
    profile_id,
    placement,
    deadly_card_count
  )
  values (
    p_match_id,
    p_profile_id,
    0,
    null
  )
  on conflict do nothing;
$$;

create or replace function public.rpc_get_match_players(
  p_match_id uuid
)
returns table (
  profile_id uuid,
  username varchar,
  avatar_key varchar,
  placement smallint,
  deadly_card_count smallint
)
language sql
as $$
  select
    p.id,
    p.username,
    p.avatar_key,
    mp.placement,
    mp.deadly_card_count
  from public.match_players mp
    inner join public.profiles p
      on p.id = mp.profile_id
  where mp.match_id = p_match_id;
$$;