create table public.game_presets (
  id uuid primary key
    default gen_random_uuid(),

  preset_key varchar(64) not null unique,

  description text not null,

  is_active boolean not null
    default true,

  created_at timestamptz not null
    default now(),

  deleted_at timestamptz
);

revoke all on public.game_presets from anon;
revoke all on public.game_presets from authenticated;