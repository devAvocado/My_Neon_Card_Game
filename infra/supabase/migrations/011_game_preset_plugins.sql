create table public.game_preset_plugins (
  game_preset_id uuid not null,

  plugin_id uuid not null,

  primary key (
    game_preset_id,
    plugin_id
  ),

  constraint game_preset_plugins_game_preset_fk
    foreign key (game_preset_id)
    references public.game_presets(id),

  constraint game_preset_plugins_plugin_fk
    foreign key (plugin_id)
    references public.game_plugins(id)
);

revoke all on public.game_preset_plugins from anon;
revoke all on public.game_preset_plugins from authenticated;