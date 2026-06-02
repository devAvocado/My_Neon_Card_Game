-- ============================================================================
-- CARDS
-- ============================================================================

insert into public.cards (
  card_key,
  description,
  category
)
values
('plus_10', 'Aumenta el valor en 10.', 'number'),
('minus_10', 'Reduce el valor en 10.', 'number'),
('plus_20', 'Aumenta el valor en 20.', 'number'),
('minus_20', 'Reduce el valor en 20.', 'number'),
('plus_50', 'Aumenta el valor en 50.', 'number'),
('minus_50', 'Reduce el valor en 50.', 'number'),

('draw_1', 'Roba 1 carta.', 'draw'),
('draw_2', 'Roba 2 cartas.', 'draw'),
('draw_3', 'Roba 3 cartas.', 'draw'),

('discard_1', 'Descarta 1 carta.', 'discard'),
('discard_2', 'Descarta 2 cartas.', 'discard'),

('steal_1', 'Roba 1 carta de otro jugador.', 'steal'),
('steal_random', 'Roba una carta aleatoria.', 'steal'),

('swap_hand', 'Intercambia tu mano con otro jugador.', 'special'),
('reverse_turn', 'Invierte el sentido de juego.', 'special'),
('skip_turn', 'Salta el turno de un jugador.', 'special'),

('trash', 'Carta basura sin efecto.', 'trash'),
('mega_trash', 'Carta basura pesada.', 'trash'),

('shield', 'Bloquea un efecto.', 'defense'),
('counter', 'Cancela una carta jugada.', 'defense');

-- ============================================================================
-- DECK PRESETS
-- ============================================================================

select *
from public.rpc_create_deck_preset(
  'basic',
  'Deck inicial balanceado'
);

select *
from public.rpc_create_deck_preset(
  'chaos',
  'Deck enfocado en interacción y caos'
);

select *
from public.rpc_create_deck_preset(
  'numbers_only',
  'Deck basado únicamente en valores numéricos'
);

-- ============================================================================
-- BASIC
-- ============================================================================

select rpc_add_card_to_deck_preset('basic', 'plus_10', 4);
select rpc_add_card_to_deck_preset('basic', 'minus_10', 4);

select rpc_add_card_to_deck_preset('basic', 'plus_20', 2);
select rpc_add_card_to_deck_preset('basic', 'minus_20', 2);

select rpc_add_card_to_deck_preset('basic', 'draw_1', 2);
select rpc_add_card_to_deck_preset('basic', 'draw_2', 2);

select rpc_add_card_to_deck_preset('basic', 'shield', 2);

select rpc_add_card_to_deck_preset('basic', 'trash', 2);

-- ============================================================================
-- CHAOS
-- ============================================================================

select rpc_add_card_to_deck_preset('chaos', 'steal_1', 3);
select rpc_add_card_to_deck_preset('chaos', 'steal_random', 3);

select rpc_add_card_to_deck_preset('chaos', 'swap_hand', 3);
select rpc_add_card_to_deck_preset('chaos', 'reverse_turn', 2);

select rpc_add_card_to_deck_preset('chaos', 'skip_turn', 3);

select rpc_add_card_to_deck_preset('chaos', 'draw_3', 2);

select rpc_add_card_to_deck_preset('chaos', 'counter', 2);

select rpc_add_card_to_deck_preset('chaos', 'mega_trash', 2);

-- ============================================================================
-- NUMBERS ONLY
-- ============================================================================

select rpc_add_card_to_deck_preset('numbers_only', 'plus_10', 4);
select rpc_add_card_to_deck_preset('numbers_only', 'minus_10', 4);

select rpc_add_card_to_deck_preset('numbers_only', 'plus_20', 4);
select rpc_add_card_to_deck_preset('numbers_only', 'minus_20', 4);

select rpc_add_card_to_deck_preset('numbers_only', 'plus_50', 2);
select rpc_add_card_to_deck_preset('numbers_only', 'minus_50', 2);