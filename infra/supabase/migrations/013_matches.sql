create table public.matches (
  id uuid primary key
    default gen_random_uuid(),

  game_preset_id uuid not null,

  deck_preset_id uuid not null,

  status varchar(16) not null
    check (
      status in (
        'waiting',
        'active',
        'finished',
        'cancelled'
      )
    ),

  started_at timestamptz,

  finished_at timestamptz,

  duration_seconds integer,

  created_at timestamptz not null
    default now(),

  constraint matches_game_preset_fk
    foreign key (game_preset_id)
    references public.game_presets(id),

  constraint matches_deck_preset_fk
    foreign key (deck_preset_id)
    references public.deck_presets(id)
);

create index matches_status_idx
on public.matches(status);

create index matches_created_at_idx
on public.matches(created_at);

revoke all on public.matches from anon;
revoke all on public.matches from authenticated;