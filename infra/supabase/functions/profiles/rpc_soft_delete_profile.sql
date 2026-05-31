create or replace function public.rpc_soft_delete_profile(
  p_id uuid
)
returns void
language plpgsql
as $$
begin
  update public.profiles
  set deleted_at = now()
  where profiles.id = p_id;
end;
$$;