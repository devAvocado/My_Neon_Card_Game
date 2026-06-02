-- ============================================================================
-- CARDS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- rpc_get_cards
--
-- Obtiene todas las cartas activas que no han sido eliminadas lógicamente.
--
-- Uso:
--   select * from rpc_get_cards();
--
-- Retorna:
--   id
--   card_key
--   description
--   category
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_cards()
returns table (
  id uuid,
  card_key varchar,
  description text,
  category varchar
)
language sql
as $$
  select
    c.id,
    c.card_key,
    c.description,
    c.category
  from public.cards c
  where c.is_active = true
    and c.deleted_at is null
  order by c.card_key;
$$;

-- ----------------------------------------------------------------------------
-- rpc_get_cards_by_category
--
-- Obtiene todas las cartas activas pertenecientes a una categoría.
--
-- Parámetros:
--   p_category
--
-- Uso:
--   select * from rpc_get_cards_by_category('number');
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_cards_by_category(
  p_category varchar
)
returns table (
  id uuid,
  card_key varchar,
  description text,
  category varchar
)
language sql
as $$
  select
    c.id,
    c.card_key,
    c.description,
    c.category
  from public.cards c
  where c.is_active = true
    and c.deleted_at is null
    and c.category = trim(p_category)
  order by c.card_key;
$$;

-- ----------------------------------------------------------------------------
-- rpc_get_card
--
-- Obtiene una carta específica mediante card_key.
--
-- Parámetros:
--   p_card_key
--
-- Uso:
--   select * from rpc_get_card('plus_10');
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_card(
  p_card_key varchar
)
returns table (
  id uuid,
  card_key varchar,
  description text,
  category varchar
)
language sql
as $$
  select
    c.id,
    c.card_key,
    c.description,
    c.category
  from public.cards c
  where c.card_key = trim(p_card_key)
    and c.deleted_at is null
  limit 1;
$$;

-- ============================================================================
-- DECK PRESETS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- rpc_create_deck_preset
--
-- Crea un nuevo deck preset.
--
-- Parámetros:
--   p_preset_key
--   p_description
--
-- Uso:
--   select *
--   from rpc_create_deck_preset(
--     'basic',
--     'Deck inicial del juego'
--   );
-- ----------------------------------------------------------------------------
create or replace function public.rpc_create_deck_preset(
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
  insert into public.deck_presets (
    preset_key,
    description
  )
  values (
    trim(p_preset_key),
    trim(p_description)
  )
  returning
    deck_presets.id,
    deck_presets.preset_key,
    deck_presets.description;
end;
$$;

-- ----------------------------------------------------------------------------
-- rpc_get_deck_presets
--
-- Obtiene todos los presets activos.
--
-- Uso:
--   select * from rpc_get_deck_presets();
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_deck_presets()
returns table (
  id uuid,
  preset_key varchar,
  description text
)
language sql
as $$
  select
    dp.id,
    dp.preset_key,
    dp.description
  from public.deck_presets dp
  where dp.is_active = true
    and dp.deleted_at is null
  order by dp.preset_key;
$$;

-- ----------------------------------------------------------------------------
-- rpc_delete_deck_preset
--
-- Realiza borrado lógico de un preset.
--
-- Parámetros:
--   p_preset_key
--
-- Uso:
--   select rpc_delete_deck_preset('basic');
-- ----------------------------------------------------------------------------
create or replace function public.rpc_delete_deck_preset(
  p_preset_key varchar
)
returns void
language plpgsql
as $$
begin

  update public.deck_presets
  set
    deleted_at = now(),
    is_active = false
  where preset_key = trim(p_preset_key);
end;
$$;

-- ============================================================================
-- DECK PRESET CARDS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- rpc_add_card_to_deck_preset
--
-- Agrega una carta a un preset.
--
-- Si la relación ya existe:
--   actualiza quantity.
--
-- Si no existe:
--   crea la relación.
--
-- Parámetros:
--   p_preset_key
--   p_card_key
--   p_quantity
--
-- Uso:
--   select rpc_add_card_to_deck_preset(
--     'basic',
--     'plus_10',
--     4
--   );
-- ----------------------------------------------------------------------------
create or replace function public.rpc_add_card_to_deck_preset(
  p_preset_key varchar,
  p_card_key varchar,
  p_quantity integer
)
returns void
language plpgsql
as $$
declare
  v_preset_id uuid;
  v_card_id uuid;
begin

  select id
  into v_preset_id
  from public.deck_presets
  where preset_key = trim(p_preset_key)
    and deleted_at is null;

  select id
  into v_card_id
  from public.cards
  where card_key = trim(p_card_key)
    and deleted_at is null;

  insert into public.deck_preset_cards (
    deck_preset_id,
    card_id,
    quantity
  )
  values (
    v_preset_id,
    v_card_id,
    p_quantity
  )
  on conflict (
    deck_preset_id,
    card_id
  )
  do update
  set quantity = excluded.quantity;
end;
$$;

-- ----------------------------------------------------------------------------
-- rpc_remove_card_from_deck_preset
--
-- Elimina una carta de un preset.
--
-- Parámetros:
--   p_preset_key
--   p_card_key
--
-- Uso:
--   select rpc_remove_card_from_deck_preset(
--     'basic',
--     'plus_10'
--   );
-- ----------------------------------------------------------------------------
create or replace function public.rpc_remove_card_from_deck_preset(
  p_preset_key varchar,
  p_card_key varchar
)
returns void
language sql
as $$
  delete from public.deck_preset_cards dpc
  using public.deck_presets dp,
        public.cards c
  where dpc.deck_preset_id = dp.id
    and dpc.card_id = c.id
    and dp.preset_key = trim(p_preset_key)
    and c.card_key = trim(p_card_key);
$$;

-- ----------------------------------------------------------------------------
-- rpc_get_deck_definition
--
-- Devuelve la definición completa de un preset.
--
-- Esta función es la principal consumida por el deck factory.
--
-- Parámetros:
--   p_preset_key
--
-- Uso:
--   select *
--   from rpc_get_deck_definition('basic');
--
-- Resultado:
--   plus_10  | 4
--   minus_10 | 4
--   trash    | 1
-- ----------------------------------------------------------------------------
create or replace function public.rpc_get_deck_definition(
  p_preset_key varchar
)
returns table (
  card_key varchar,
  quantity integer
)
language sql
as $$
  select
    c.card_key,
    dpc.quantity
  from public.deck_preset_cards dpc
    inner join public.deck_presets dp
      on dp.id = dpc.deck_preset_id
    inner join public.cards c
      on c.id = dpc.card_id
  where dp.preset_key = trim(p_preset_key)
    and dp.deleted_at is null
    and c.deleted_at is null
    and c.is_active = true
  order by c.card_key;
$$;