create or replace function public.rpc_get_or_create_profile(
  p_username varchar,
  p_avatar_key varchar
)
returns table (
  id uuid,
  username varchar,
  avatar_key varchar,
  created_at timestamptz
)
language plpgsql
as $$
begin
  update public.profiles
  set last_seen_at = now()
  where profiles.username = trim(p_username)
    and profiles.avatar_key = trim(p_avatar_key)
    and profiles.deleted_at is null;

  return query
  select
    profiles.id,
    profiles.username,
    profiles.avatar_key,
    profiles.created_at
  from public.profiles
  where profiles.username = trim(p_username)
    and profiles.avatar_key = trim(p_avatar_key)
    and profiles.deleted_at is null;

  if not found then
    return query
    insert into public.profiles (
      username,
      avatar_key
    )
    values (
      trim(p_username),
      trim(p_avatar_key)
    )
    returning
      profiles.id,
      profiles.username,
      profiles.avatar_key,
      profiles.created_at;
  end if;
end;
$$;