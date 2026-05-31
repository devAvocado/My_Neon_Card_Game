create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key
    default gen_random_uuid(),

  username varchar(24) not null
    check (
      char_length(username) >= 2
      and char_length(username) <= 24
    ),

  avatar_key varchar(32) not null
    check (
      char_length(avatar_key) >= 3
      and char_length(avatar_key) <= 32
    ),

  created_at timestamptz not null
    default now(),

  last_seen_at timestamptz not null
    default now(),

  deleted_at timestamptz
);

create unique index profiles_username_avatar_unique
on public.profiles(username, avatar_key)
where deleted_at is null;

revoke all on public.profiles from anon;
revoke all on public.profiles from authenticated;