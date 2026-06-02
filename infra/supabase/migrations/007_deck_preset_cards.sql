create table public.deck_preset_cards (
  deck_preset_id uuid not null,
  card_id uuid not null,

  quantity integer not null
    check (quantity > 0),

  created_at timestamptz not null
    default now(),

  primary key (
    deck_preset_id,
    card_id
  ),

  constraint deck_preset_cards_deck_preset_fk
    foreign key (deck_preset_id)
    references public.deck_presets(id),

  constraint deck_preset_cards_card_fk
    foreign key (card_id)
    references public.cards(id)
);

revoke all on public.deck_preset_cards from anon;
revoke all on public.deck_preset_cards from authenticated;