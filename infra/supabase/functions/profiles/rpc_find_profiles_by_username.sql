create or replace function public.rpc_find_profiles_by_username(
  p_username varchar
)
returns table (
  avatar_key varchar
)
language plpgsql
as $$
begin
  return query
  select
    profiles.avatar_key
  from public.profiles
  where profiles.username = trim(p_username)
    and profiles.deleted_at is null
  order by profiles.last_seen_at desc
  limit 10;
end;
$$;