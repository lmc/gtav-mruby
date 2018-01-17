GTAV.register(:RuntimeReloader,CONFIG["scripts.RuntimeReloader.enabled"]) do
  GTAV.wait(0)

  GTAV[:RuntimeHost].register_menu_item(:RuntimeReloaderButton, type: :button, label: "Reload scripts") do |item|
    GTAV.reset_mruby_next_tick!
  end

  loop do
    if GTAV.is_key_just_up(CONFIG["scripts.RuntimeReloader.key"])
      GTAV.reset_mruby_next_tick!
    end
    GTAV.wait(0)
  end
end