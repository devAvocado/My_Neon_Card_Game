-- ============================================================================
-- MATCHES
-- ============================================================================
--
-- Las partidas terminadas son históricas y no deben modificarse.
--
-- ============================================================================

-- ----------------------------------------------------------------------------
-- rpc_create_match
--
-- Crea una nueva partida.
--
-- Estado inicial:
--   waiting
--
-- Parámetros:
--   p_game_preset_key
--   p_deck_preset_key
--
-- Uso:
--   select *
--   from rpc_create_match(
--     'classic',
--     'basic'
--   );
--
-- Retorna:
--   id
-- ----------------------------------------------------------------------------
create or replace function public.rpc_create_match(
  p_game_preset_key varchar,
  p_deck_preset_key varchar
)
returns table (
  id uuid
)
language plpgsql
as $$
declare
  v_game_preset_id uuid;
  v_deck_preset_id uuid;
begin

  select gp.id
  into v_game_preset_id
  from public.game_presets gp
  where gp.preset_key = trim(p_game_preset_key)
    and gp.deleted_at is null;

  select dp.id
  into v_deck_preset_id
  from public.deck_presets dp
  where dp.preset_key = trim(p_deck_preset_key)
    and dp.deleted_at is null;

  return query
  insert into public.matches (
    game_preset_id,
    deck_preset_id,
    status
  )
  values (
    v_game_preset_id,
    v_deck_preset_id,
    'waiting'
  )
  returning matches.id;

end;
$$;

-- ----------------------------------------------------------------------------
-- rpc_get_match
--
-- Obtiene una partida específica.
--
-- Parámetros:
--   p_match_id
--
-- Uso:
--   select *
--   from rpc_get_match(
--     'uuid'
--   );
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_match(
  p_match_id uuid
)
returns table (
  id uuid,
  status varchar,
  started_at timestamptz,
  finished_at timestamptz,
  duration_seconds integer
)
language sql
as $$
  select
    m.id,
    m.status,
    m.started_at,
    m.finished_at,
    m.duration_seconds
  from public.matches m
  where m.id = p_match_id;
$$;

-- ----------------------------------------------------------------------------
-- rpc_add_player_to_match
--
-- Agrega un jugador a una partida.
--
-- Parámetros:
--   p_match_id
--   p_profile_id
--
-- Uso:
--   select rpc_add_player_to_match(
--     'match_uuid',
--     'profile_uuid'
--   );
-- ----------------------------------------------------------------------------
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
    final_card_count
  )
  values (
    p_match_id,
    p_profile_id,
    0,
    null
  )
  on conflict do nothing;
$$;
-- ----------------------------------------------------------------------------
-- rpc_remove_player_from_match
--
-- Elimina un jugador de una partida.
--
-- Parámetros:
--   p_match_id
--   p_profile_id
--
-- Uso:
--   select rpc_remove_player_from_match(
--     'match_uuid',
--     'profile_uuid'
--   );
-- ----------------------------------------------------------------------------
create or replace function public.rpc_remove_player_from_match(
  p_match_id uuid,
  p_profile_id uuid
)
returns void
language sql
as $$
  delete from public.match_players
  where match_id = p_match_id
    and profile_id = p_profile_id;
$$;
-- ----------------------------------------------------------------------------
-- rpc_get_match_players
--
-- Obtiene los jugadores asociados a una partida.
--
-- Parámetros:
--   p_match_id
--
-- Uso:
--   select *
--   from rpc_get_match_players(
--     'match_uuid'
--   );
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_match_players(
  p_match_id uuid
)
returns table (
  profile_id uuid,
  username varchar,
  avatar_key varchar,
  placement smallint,
  final_card_count smallint
)
language sql
as $$
  select
    p.id,
    p.username,
    p.avatar_key,
    mp.placement,
    mp.final_card_count
  from public.match_players mp
    inner join public.profiles p
      on p.id = mp.profile_id
  where mp.match_id = p_match_id;
$$;

-- ----------------------------------------------------------------------------
-- rpc_start_match
--
-- Inicia una partida.
--
-- Parámetros:
--   p_match_id
--
-- Uso:
--   select rpc_start_match(
--     'match_uuid'
--   );
-- ----------------------------------------------------------------------------
create or replace function public.rpc_start_match(
  p_match_id uuid
)
returns void
language plpgsql
as $$
begin

  update public.matches
  set
    status = 'active',
    started_at = now()
  where id = p_match_id;

end;
$$;

-- ----------------------------------------------------------------------------
-- rpc_finish_match
--
-- Finaliza una partida.
--
-- Calcula la duración utilizando started_at.
--
-- Parámetros:
--   p_match_id
--
-- Uso:
--   select rpc_finish_match(
--     'match_uuid'
--   );
-- ----------------------------------------------------------------------------
create or replace function public.rpc_finish_match(
  p_match_id uuid
)
returns void
language plpgsql
as $$
begin

  update public.matches
  set
    status = 'finished',
    finished_at = now(),
    duration_seconds =
      extract(
        epoch
        from (
          now() - started_at
        )
      )::integer
  where id = p_match_id;

end;
$$;

-- ----------------------------------------------------------------------------
-- rpc_get_recent_matches
--
-- Obtiene las partidas más recientes.
--
-- Parámetros:
--   p_limit
--
-- Uso:
--   select *
--   from rpc_get_recent_matches(20);
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_recent_matches(
  p_limit integer
)
returns table (
  id uuid,
  status varchar,
  created_at timestamptz
)
language sql
as $$
  select
    m.id,
    m.status,
    m.created_at
  from public.matches m
  order by m.created_at desc
  limit p_limit;
$$;


-- ============================================================================
-- REPLAYS
-- ============================================================================
--
-- Sistema de reproducción determinística.
--
-- Una partida puede reconstruirse mediante:
--
--   initial_seed
--   +
--   replay_commands ordenados por sequence_number
--
-- ============================================================================
-- ----------------------------------------------------------------------------
-- rpc_create_replay
--
-- Crea un replay asociado a una partida.
--
-- Existe una relación 1:1 entre matches y replays.
--
-- Parámetros:
--   p_match_id
--   p_initial_seed
--
-- Uso:
--   select *
--   from rpc_create_replay(
--     'match_uuid',
--     123456789
--   );
--
-- Retorna:
--   id
-- ----------------------------------------------------------------------------
create or replace function public.rpc_create_replay(
  p_match_id uuid,
  p_initial_seed bigint
)
returns table (
  id uuid
)
language plpgsql
as $$
begin

  return query
  insert into public.replays (
    match_id,
    initial_seed
  )
  values (
    p_match_id,
    p_initial_seed
  )
  returning replays.id;

end;
$$;
-- ----------------------------------------------------------------------------
-- rpc_get_replay
--
-- Obtiene la información principal de un replay.
--
-- Parámetros:
--   p_match_id
--
-- Uso:
--   select *
--   from rpc_get_replay(
--     'match_uuid'
--   );
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_replay(
  p_match_id uuid
)
returns table (
  replay_id uuid,
  match_id uuid,
  initial_seed bigint,
  created_at timestamptz
)
language sql
as $$
  select
    r.id,
    r.match_id,
    r.initial_seed,
    r.created_at
  from public.replays r
  where r.match_id = p_match_id;
$$;
-- ----------------------------------------------------------------------------
-- rpc_append_replay_command
--
-- Agrega un comando al replay.
--
-- Los comandos deben insertarse utilizando un sequence_number
-- incremental para garantizar una reproducción determinística.
--
-- Parámetros:
--   p_replay_id
--   p_sequence_number
--   p_command_json
--
-- Uso:
--   select rpc_append_replay_command(
--     'replay_uuid',
--     1,
--     '{"type":"play_card"}'::jsonb
--   );
-- ----------------------------------------------------------------------------
create or replace function public.rpc_append_replay_command(
  p_replay_id uuid,
  p_sequence_number integer,
  p_command_json jsonb
)
returns void
language sql
as $$
  insert into public.replay_commands (
    replay_id,
    sequence_number,
    command_json
  )
  values (
    p_replay_id,
    p_sequence_number,
    p_command_json
  );
$$;
-- ----------------------------------------------------------------------------
-- rpc_get_replay_commands
--
-- Obtiene todos los comandos asociados a un replay.
--
-- Los comandos se devuelven ordenados por sequence_number.
--
-- Parámetros:
--   p_replay_id
--
-- Uso:
--   select *
--   from rpc_get_replay_commands(
--     'replay_uuid'
--   );
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_replay_commands(
  p_replay_id uuid
)
returns table (
  sequence_number integer,
  command_json jsonb,
  created_at timestamptz
)
language sql
as $$
  select
    rc.sequence_number,
    rc.command_json,
    rc.created_at
  from public.replay_commands rc
  where rc.replay_id = p_replay_id
  order by rc.sequence_number;
$$;

-- ----------------------------------------------------------------------------
-- rpc_get_replay_command_count
--
-- Obtiene la cantidad total de comandos registrados
-- para un replay.
--
-- Parámetros:
--   p_replay_id
--
-- Uso:
--   select *
--   from rpc_get_replay_command_count(
--     'replay_uuid'
--   );
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_replay_command_count(
  p_replay_id uuid
)
returns table (
  command_count bigint
)
language sql
as $$
  select
    count(*)
  from public.replay_commands rc
  where rc.replay_id = p_replay_id;
$$;

-- ----------------------------------------------------------------------------
-- rpc_get_replay_by_match
--
-- Obtiene el replay asociado a una partida.
--
-- Parámetros:
--   p_match_id
--
-- Uso:
--   select *
--   from rpc_get_replay_by_match(
--     'match_uuid'
--   );
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_replay_by_match(
  p_match_id uuid
)
returns table (
  replay_id uuid,
  initial_seed bigint
)
language sql
as $$
  select
    r.id,
    r.initial_seed
  from public.replays r
  where r.match_id = p_match_id;
$$;

