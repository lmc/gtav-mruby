
GTAV.register(:RuntimeMenu,true) do
   
  @@RuntimeMenu_items = {}
  def self.register_menu_item(name,options = {},&block)
    log "register_menu_item - #{name}"
    options[:action] = block if block_given?
    options[:type]   = options[:type] || :button
    @@RuntimeMenu_items[name] = {id: name, label: "#{name}"}.merge(options)
  end
  
  RuntimeMenu = UiMenu.new({
    id: :RuntimeMenu,
  })
  LONG_STR = <<-STR
index usually 2
returns true if the last input method was made with mouse + keyboard, false if it WAS made with a gamepad
0, 1 and 2 used in the scripts. 0 is by far the most common of them.
STR
  def RuntimeMenu.items
    items = []
    items << { type: :header , label: "MRuby Runtime", label_sub: "ASI v#{GTAV.asi_version}, Runtime v#{GTAV.rb_version}" }
    items << { type: :button , label: "Fibers", action: lambda{ UiMenu.show(:RuntimeMenuFibers) } , help: "Pause/Resume running scripts" }
    items << { type: :button , label: "Config", action: lambda{ UiMenu.show(:RuntimeMenuConfig) } , help: "View/Edit runtime and mod settings" }
    @@RuntimeMenu_items.each_pair do |name,item|
      items << item.dup
    end
    items << { type: :help }
    items
  end

  RuntimeMenuFibers = UiMenu.new({
    id: :RuntimeMenuFibers,
  })
  def RuntimeMenuFibers.items
    items = []
    items << { type: :header , label: "MRuby Runtime", label_sub: "Fibers" }
    GTAV.fiber_wait_hash.each_pair do |fiber_name,fiber_wait|
      items << {
        type: :checkbox,
        label: "#{fiber_name}",
        id: fiber_name,
        # collection: {false=>"Off",true=>"On"},
        action: lambda{|item|
          log "selected #{item.id} #{item.value}"
          GTAV.enable_fiber(item.id,item.value)
        }
      }
    end
    items
  end

  def RuntimeMenuFibers.defaults(values = {})
    defaults = {}
    GTAV.fiber_wait_hash.each_pair do |fiber_name,fiber_wait|
      defaults[fiber_name] = fiber_wait >= 999999999 ? false : true
    end
    defaults
  end

  def RuntimeMenuFibers.on_nav_back_pressed
    UiMenu.show(:RuntimeMenu)
  end

  RuntimeMenuConfig = UiMenu.new({
    id: :RuntimeMenuConfig,
  })

  CONFIG_ITEMS = {
    "console.enabled" => { type: :checkbox, help: "Select to place your waypoint at a set location." },
    "console.remote.enabled" => { type: :checkbox },
    "console.remote.enabled1" => { type: :checkbox },
    "console.remote.enabled12" => { type: :checkbox },
    "console.remote.enabled123" => { type: :checkbox },
  }

  def RuntimeMenuConfig.items
    items = []
    items << { type: :header , label: "MRuby Runtime", label_sub: "Config" }
    CONFIG_ITEMS.each_pair do |config_name,options|
      options = options.merge(id: config_name, label: config_name)
      options[:action] = lambda{|i| GTAV[:RuntimeMenu].set_config_value(i)}
      items << options
    end
    items << { type: :help }
    items
  end

  def RuntimeMenuConfig.defaults(values = {})
    defaults = {}
    CONFIG_ITEMS.each_pair do |config_name,options|
      if options[:type] == :checkbox
        defaults[config_name] = CONFIG[config_name] || false
      else
        defaults[config_name] = CONFIG[config_name]
      end
    end
    defaults
  end

  def RuntimeMenuConfig.on_nav_back_pressed
    UiMenu.show(:RuntimeMenu)
  end

  def set_config_value(item)
    CONFIG[ item.id ] = item.value
    CONFIG.write_to_file
  end

  GTAV.wait(0)

  GTAV[:RuntimeMenu].register_menu_item(:ListTest, type: :list, collection: enum_to_hash(Control),default: -1) do |item|
    log "#{item.value}"
  end
  GTAV[:RuntimeMenu].register_menu_item(:IntegerTest, type: :integer, min: -5, max: 5, default: -1) do |item|
    log "#{item.value}"
  end
  GTAV[:RuntimeMenu].register_menu_item(:FloatTest, type: :float, min: -5.0, max: 15.0, step: 0.1, default: -4.20, round: 1) do |item|
    log "#{item.value}"
  end
  GTAV[:RuntimeMenu].register_menu_item(:Map, type: :select, collection: {0=>"Small",1=>"Big",2=>"Full"}, default: 0) do |item|
    case item.value
    when 0
      UI::_SET_RADAR_BIGMAP_ENABLED(false,false)
    when 1
      UI::_SET_RADAR_BIGMAP_ENABLED(true,false)
    when 2
      UI::_SET_RADAR_BIGMAP_ENABLED(true,true)
    end
  end

  GTAV[:RuntimeMenu].register_menu_item(:Pause, type: :checkbox, default: false) do |item|
    GAMEPLAY::SET_GAME_PAUSED(item.value)
    
  end
  
  GTAV[:RuntimeMenu].register_menu_item(:Teleport,
    type:     :button,
    enabled:  lambda{|i| !!UI::GET_FIRST_BLIP_INFO_ID(BlipSprite::Waypoint) },
    help:     lambda{|i| i.enabled? ? "Teleport to waypoint" : "No waypoint to teleport to"}
  ) do |item|
    if blip = UI::GET_FIRST_BLIP_INFO_ID(BlipSprite::Waypoint)
      coords = UI::GET_BLIP_COORDS(blip)
      entity = PLAYER::PLAYER_PED_ID()
      entity = PED::GET_VEHICLE_PED_IS_USING(entity) if PED::IS_PED_IN_ANY_VEHICLE(entity,false)
      coords.z = -25.0
      # ENTITY::SET_ENTITY_COORDS(entity,*coords,false,false,false,true)
      until (gz = GAMEPLAY::GET_GROUND_Z_FOR_3D_COORD(*coords,false)) > 0.0 || coords.z > 800.0
        GTAV.wait(30)
        ENTITY::SET_ENTITY_COORDS(entity,*coords,false,false,false,true)
        # log "coords: #{coords}"
        gz = GAMEPLAY::GET_GROUND_Z_FOR_3D_COORD(*coords,false)
        # log "gz: #{gz}"
        coords.z += 25.0
      end
      coords.z = gz
      ENTITY::SET_ENTITY_COORDS(entity,*coords,false,false,false,true)
      log "final gz: #{gz}"
    else
      log "No waypoint for teleport"
    end
  end
  
  GTAV.wait(0)
  dpad_down_pressed_at = nil
  dpad_down_short_press = false
  loop do

    # only block/listen for inputs if the menu is closed, and the mobile phone/interaction menu is not in use
    if !UiMenu.active && !PED::IS_PED_RUNNING_MOBILE_PHONE_TASK(PLAYER::PLAYER_PED_ID()) && CONTROLS::IS_CONTROL_ENABLED(0,Control::Context)
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
        UiMenu.show(:RuntimeMenu)
      end
    end

    UiMenu.draw

    # UiMenu[:waifu].show({selected: nil})
    # UiMenu[:waifu].draw(0.75,0.3,0.2)

    GTAV.wait(0)

  end

end
