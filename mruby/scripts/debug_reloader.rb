GTAV.register(:DebugReloader) do
  loop do
    if GTAV.is_key_just_up(0x7A)
      GTAV.reset_mruby_next_tick!
    end
    GTAV.wait(100)
  end
end