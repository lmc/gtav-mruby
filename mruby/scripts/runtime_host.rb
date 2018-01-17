GTAV.register(:RuntimeMenu) do
  def self.register_menu_item(*args,&block)
    GTAV[:RuntimeHost].register_menu_item(*args,&block)
  end
  self.terminate!
end

GTAV.register(:RuntimeHost) do
   
  @@RuntimeMenu_items = {}
  def self.register_menu_item(name,options = {},&block)
    log "register_menu_item - #{name}"
    # caller.each{|c| log "  #{c}"}
    options[:type]   = options[:type] || :button
    if options[:type] == :button
      options[:action] = block if block_given?
    else
      options[:change] = block if block_given?
    end
    @@RuntimeMenu_items[name] = {id: name, label: "#{name}"}.merge(options)
  end

  GTAV.wait(0)
  
  RuntimeMenu = GUI::Menu.new({ id: :RuntimeMenu , x: 0.01, y: 0.01 })

  RuntimeMenu.items do |items|
    items << { type: :header , title: "MRuby Runtime", subtitle: "MRuby #{MRUBY_VERSION}, ASI #{GTAV.asi_version}, Runtime #{GTAV.rb_version}" }
    @@RuntimeMenu_items.each_pair do |name,item|
      items << item.dup
    end
    items << { type: :help }
    items
  end

  GTAV.wait(0)
  dpad_down_pressed_at = nil
  dpad_down_short_press = false
  loop do

    # only block/listen for inputs if the menu is closed, and the mobile phone/interaction menu is not in use
    if !GUI::Menu.active && !PED::IS_PED_RUNNING_MOBILE_PHONE_TASK(PLAYER::PLAYER_PED_ID()) && CONTROLS::IS_CONTROL_ENABLED(0,Control::Context)
 
      # block map zoom-out (short d-pad down) and listen for it ourselves
      # make sure we don't block long d-pad down (character switcher)
      CONTROLS::DISABLE_CONTROL_ACTION(0,Control::HUDSpecial,true)
      dpad_down_short_press = false
      if CONTROLS::IS_DISABLED_CONTROL_PRESSED(0,Control::HUDSpecial)
        dpad_down_pressed_at = GTAV.time if !dpad_down_pressed_at
      elsif dpad_down_pressed_at
        if (GTAV.time - dpad_down_pressed_at) < 200
          dpad_down_short_press = true
        end
        dpad_down_pressed_at = nil
      end

      if GTAV.is_key_just_up(Key::F10) || dpad_down_short_press
        AUDIO::PLAY_SOUND_FRONTEND(-1,"SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0)
        GTAV.wait(0)
        GUI::Menu.show(:RuntimeMenu)
      end
    end

    GUI::Menu.draw

    GTAV.wait(0)

  end

end

GTAV.register(name: :RuntimeHostNotifications) do
  GTAV.wait(0)
  GTAV.wait(0)
  GTAV.wait(0)

  about_str = "github.com/lmc/gtav-mruby\n"
  about_str << "MRuby #{MRUBY_VERSION}\n"
  about_str << "ASI #{GTAV.asi_version}\n"
  about_str << "Runtime #{GTAV.rb_version}\n"
  about_str << "Game #{GTAV.game_version}\n"
  about_str << "loaded #{GTAV.fibers.size - 1} scripts"

  GTAV[:RuntimeHost].register_menu_item(:RuntimeHostNotifications,
    type: :button,
    label: "About",
    help: ->(i){ about_str },
  ) do |item|

  end

  @faded_in_at = nil
  @shown_load_message = false

  loop do

    if !@faded_in_at
      if !CAM::IS_SCREEN_FADED_OUT()
        @faded_in_at = GTAV.time
      end
    end

    if @faded_in_at && !@shown_load_message
      UI::_0x55598D21339CB998(0.5)

      notification = GUI::Notification.new(about_str)
      notification.draw
      @shown_load_message = true
    end
    
    # draw any errored scripts as notifications
    @last_checked_at ||= 0
    if GTAV.respond_to?(:logger_buffer)# && @last_checked_at >= 0
      meta = GTAV.logger_meta_buffer.to_a
      pending_errors = []
      GTAV.logger_buffer.to_a.each_with_index do |line,i|
        next if !meta[i]
        next if !meta[i][1]
        next if meta[i][1] < @last_checked_at
        if meta[i][0] && meta[i][0][0..1] == [:error, :fiber]
          script_name = meta[i][0][3]
          script_index = meta[i][0][5]
          pending_errors << {type: :fiber_error, script_name: script_name, script_index: script_index, message: "", backtrace: []}
        elsif meta[i][0] && meta[i][0] == [:error, :message] && pending_errors[-1]
          pending_errors[-1][:message] = line
        elsif meta[i][0] && meta[i][0] == [:error, :backtrace] && pending_errors[-1]
          pending_errors[-1][:backtrace] << line
        end
      end
      @last_checked_at = GTAV.time_usec
      pending_errors.each_with_index do |error,index|
        str = "~r~ERROR in #{error[:script_index]} #{error[:script_name]}\n"
        str << "#{error[:message].gsub("<",'(').gsub(">",')')}"
        notification = GUI::Notification.new(str)
        notification.draw
      end
    end

    GTAV.wait(250)
  end
end