create table public.replays (
  id uuid primary key
    default gen_random_uuid(),

  match_id uuid not null unique,

  initial_seed bigint not null,

  created_at timestamptz not null
    default now(),

  constraint replays_match_fk
    foreign key (match_id)
    references public.matches(id)
);

revoke all on public.replays from anon;
revoke all on public.replays from authenticated;