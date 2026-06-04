-- ============================================================================
-- GAME PLUGINS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- rpc_get_game_plugins
--
-- Obtiene todos los plugins activos.
--
-- Uso:
--   select * from rpc_get_game_plugins();
--
-- Retorna:
--   id
--   plugin_key
--   description
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_game_plugins()
returns table (
  id uuid,
  plugin_key varchar,
  description text
)
language sql
as $$
  select
    gp.id,
    gp.plugin_key,
    gp.description
  from public.game_plugins gp
  where gp.is_active = true
    and gp.deleted_at is null
  order by gp.plugin_key;
$$;
-- ----------------------------------------------------------------------------
-- rpc_get_game_plugin
--
-- Obtiene un plugin específico mediante plugin_key.
--
-- Parámetros:
--   p_plugin_key
--
-- Uso:
--   select * from rpc_get_game_plugin('turn_timer');
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_game_plugin(
  p_plugin_key varchar
)
returns table (
  id uuid,
  plugin_key varchar,
  description text
)
language sql
as $$
  select
    gp.id,
    gp.plugin_key,
    gp.description
  from public.game_plugins gp
  where gp.plugin_key = trim(p_plugin_key)
    and gp.deleted_at is null
  limit 1;
$$;
-- ============================================================================
-- GAME PRESETS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- rpc_create_game_preset
--
-- Crea un nuevo preset de reglas.
--
-- Parámetros:
--   p_preset_key
--   p_description
--
-- Uso:
--   select *
--   from rpc_create_game_preset(
--     'classic',
--     'Reglas clásicas'
--   );
-- ----------------------------------------------------------------------------
create or replace function public.rpc_create_game_preset(
  p_preset_key varchar,
  p_description text
)
returns table (
  id uuid,
  preset_key varchar,
  description text
)
language plpgsql
as $$
begin

  return query
  insert into public.game_presets (
    preset_key,
    description
  )
  values (
    trim(p_preset_key),
    trim(p_description)
  )
  returning
    game_presets.id,
    game_presets.preset_key,
    game_presets.description;
end;
$$;
-- ----------------------------------------------------------------------------
-- rpc_get_game_presets
--
-- Obtiene todos los presets activos.
--
-- Uso:
--   select * from rpc_get_game_presets();
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_game_presets()
returns table (
  id uuid,
  preset_key varchar,
  description text
)
language sql
as $$
  select
    gp.id,
    gp.preset_key,
    gp.description
  from public.game_presets gp
  where gp.is_active = true
    and gp.deleted_at is null
  order by gp.preset_key;
$$;
-- ----------------------------------------------------------------------------
-- rpc_delete_game_preset
--
-- Realiza borrado lógico de un preset.
--
-- Parámetros:
--   p_preset_key
--
-- Uso:
--   select rpc_delete_game_preset('classic');
-- ----------------------------------------------------------------------------
create or replace function public.rpc_delete_game_preset(
  p_preset_key varchar
)
returns void
language plpgsql
as $$
begin

  update public.game_presets
  set
    deleted_at = now(),
    is_active = false
  where preset_key = trim(p_preset_key);
end;
$$;
-- ============================================================================
-- GAME PRESET PLUGINS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- rpc_add_plugin_to_game_preset
--
-- Agrega un plugin a un preset.
--
-- Si la relación ya existe:
--   no realiza ninguna acción.
--
-- Si no existe:
--   crea la relación.
--
-- Parámetros:
--   p_preset_key
--   p_plugin_key
--
-- Uso:
--   select rpc_add_plugin_to_game_preset(
--     'classic',
--     'turn_timer'
--   );
-- ----------------------------------------------------------------------------
create or replace function public.rpc_add_plugin_to_game_preset(
  p_preset_key varchar,
  p_plugin_key varchar
)
returns void
language plpgsql
as $$
declare
  v_preset_id uuid;
  v_plugin_id uuid;
begin
  select id
  into v_preset_id
  from public.game_presets
  where preset_key = trim(p_preset_key)
    and deleted_at is null;

  select id
  into v_plugin_id
  from public.game_plugins
  where plugin_key = trim(p_plugin_key)
    and deleted_at is null;

  insert into public.game_preset_plugins (
    game_preset_id,
    plugin_id
  )
  values (
    v_preset_id,
    v_plugin_id
  )
  on conflict do nothing;
end;
$$;
-- ----------------------------------------------------------------------------
-- rpc_remove_plugin_from_game_preset
--
-- Elimina un plugin de un preset.
--
-- Parámetros:
--   p_preset_key
--   p_plugin_key
--
-- Uso:
--   select rpc_remove_plugin_from_game_preset(
--     'classic',
--     'turn_timer'
--   );
-- ----------------------------------------------------------------------------
create or replace function public.rpc_remove_plugin_from_game_preset(
  p_preset_key varchar,
  p_plugin_key varchar
)
returns void
language sql
as $$
  delete from public.game_preset_plugins gpp
  using public.game_presets gp,
        public.game_plugins pl
  where gpp.game_preset_id = gp.id
    and gpp.plugin_id = pl.id
    and gp.preset_key = trim(p_preset_key)
    and pl.plugin_key = trim(p_plugin_key);
$$;
-- ----------------------------------------------------------------------------
-- rpc_get_game_preset_definition
--
-- Devuelve la definición completa de un preset.
--
-- Esta función es la principal consumida por el game engine.
--
-- Parámetros:
--   p_preset_key
--
-- Uso:
--   select *
--   from rpc_get_game_preset_definition(
--     'classic'
--   );
--
-- Resultado:
--   turn_timer
--   stack_rules
--   friendly_fire
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_game_preset_definition(
  p_preset_key varchar
)
returns table (
  plugin_key varchar
)
language sql
as $$
  select
    gp.plugin_key
  from public.game_preset_plugins gpp
    inner join public.game_presets gpr
      on gpr.id = gpp.game_preset_id
    inner join public.game_plugins gp
      on gp.id = gpp.plugin_id
  where gpr.preset_key = trim(p_preset_key)
    and gpr.deleted_at is null
    and gp.deleted_at is null
    and gp.is_active = true
  order by gp.plugin_key;
$$;
