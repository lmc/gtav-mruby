GTAV.register(:DebugReloader,CONFIG["scripts.DebugReloader.enabled"]) do
  loop do
    if GTAV.is_key_just_up(CONFIG["scripts.DebugReloader.key"])
      GTAV.reset_mruby_next_tick!
    end
    GTAV.wait(100)
  end
end