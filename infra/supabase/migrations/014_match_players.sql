create table public.match_players (
  match_id uuid not null,

  profile_id uuid not null,

  deadly_card_count smallint,

  placement integer,

  primary key (
    match_id,
    profile_id
  ),

  constraint match_players_match_fk
    foreign key (match_id)
    references public.matches(id),

  constraint match_players_profile_fk
    foreign key (profile_id)
    references public.profiles(id)
);

create index match_players_profile_idx
on public.match_players(profile_id);

revoke all on public.match_players from anon;
revoke all on public.match_players from authenticated;