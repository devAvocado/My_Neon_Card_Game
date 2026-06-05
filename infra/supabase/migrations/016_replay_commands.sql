create table public.replay_commands (
  replay_id uuid not null,

  sequence_number integer not null,

  command_json jsonb not null,

  created_at timestamptz not null
    default now(),

  primary key (
    replay_id,
    sequence_number
  ),

  constraint replay_commands_replay_fk
    foreign key (replay_id)
    references public.replays(id)
);

create index replay_commands_replay_idx
on public.replay_commands(replay_id);

revoke all on public.replay_commands from anon;
revoke all on public.replay_commands from authenticated;