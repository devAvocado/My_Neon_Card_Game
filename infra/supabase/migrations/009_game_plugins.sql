create table public.game_plugins (
  id uuid primary key
    default gen_random_uuid(),

  plugin_key varchar(64) not null unique,

  description text not null,

  is_active boolean not null
    default true,

  deleted_at timestamptz
);

revoke all on public.game_plugins from anon;
revoke all on public.game_plugins from authenticated;