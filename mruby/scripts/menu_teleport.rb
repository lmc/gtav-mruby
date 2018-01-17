GTAV.register(:MenuTeleport) do
  GTAV.wait(0)
  
  GTAV[:RuntimeMenu].register_menu_item(:MenuTeleportButton,
    label: "Teleport",
    type: :button,
    expand: ->(i){ GUI::Menu.show(:MenuTeleport) },
  )

  TELEPORT_LOCATIONS = PersistentHash.new('.\mruby\config\teleport.config.rb',nil,"TELEPORT_LOCATIONS")
  if TELEPORT_LOCATIONS.size == 0
    TELEPORT_LOCATIONS["locations.0.name"] = "World Origin"
    TELEPORT_LOCATIONS["locations.0.x"] = 0.0
    TELEPORT_LOCATIONS["locations.0.y"] = 0.0
    TELEPORT_LOCATIONS["locations.0.z"] = 0.0
    TELEPORT_LOCATIONS["locations.0.heading"] = 0.0
    TELEPORT_LOCATIONS.write_to_file
  end

  MenuTeleport = GUI::Menu.new({ id: :MenuTeleport , parent: :MenuTeleportButton })

  def MenuTeleport.items
    items = []
    items << { type: :header , title: "Teleport", subtitle: "size: #{TELEPORT_LOCATIONS.list_size("locations","name")}" }
    items << { type: :button , label: "Waypoint",
      enabled: lambda{|i| !!UI::GET_FIRST_BLIP_INFO_ID(BlipSprite::Waypoint) },
      action:  lambda{|i| GTAV[:MenuTeleport].teleport_to_waypoint() },
      help:    lambda{|i| i.enabled? ? GTAV[:MenuTeleport].location_help(:waypoint) : "No waypoint available" }
    }
    
    # buttons for each saved location
    TELEPORT_LOCATIONS.each_list("locations",[:name,:x,:y,:z,:heading]) do |hash,idx|
      items << { type: :button , label: "#{hash[:name]}", id: idx,
        action: lambda{|i| GTAV[:MenuTeleport].teleport_to_index(idx) },
        help: lambda{|i| GTAV[:MenuTeleport].location_help(idx) },
        expand: lambda{|i| GUI::Menu.show_submenu(:MenuTeleportManage, selected: 0, values: {index: idx, name: "#{hash[:name]}"}) },
      }
    end

    items << { type: :button , label: "Save new location",
      action: lambda{|i| GTAV[:MenuTeleport].save_new_location() },
      help: lambda{|i| GTAV[:MenuTeleport].location_help(:current) }
    }
    items << { type: :help }
    items
  end
  
  def MenuTeleport.on_nav_back_pressed
    GUI::Menu.show(:RuntimeMenu)
  end

  MenuTeleportManage = GUI::Menu.new({ id: :MenuTeleportManage })

  def MenuTeleportManage.items
    items = []
    items << { type: :header , title: "", title_bg: false, subtitle: "#{values[:name]}" }
    items << { type: :button , label: "Rename" ,
      action: lambda{|i| GTAV[:MenuTeleport].rename_index(i.menu.values[:index]) }
    }
    items << { type: :button , label: "Delete" ,
      action: lambda{|i| GTAV[:MenuTeleport].delete_index(i.menu.values[:index]) }
    }
    items
  end

  def MenuTeleportManage.on_nav_left_pressed
    GUI::Menu.hide_submenu()
  end
  def MenuTeleportManage.on_nav_back_pressed
    GUI::Menu.hide_submenu()
  end

  def save_new_location
    currently_selected = GUI::Menu[:MenuTeleport].selected
    next_slot = TELEPORT_LOCATIONS.list_size("locations","name")
    data = current_location_data
    
    name = "New location #{next_slot}"
    if name = get_keyboard_input(name)
      data[:name] = name
    else
      return # abort if keyboard cancelled
    end

    [:name,:x,:y,:z,:heading].each do |key|
      TELEPORT_LOCATIONS["locations.#{next_slot}.#{key}"] = data[key]
    end
    TELEPORT_LOCATIONS.write_to_file

    GUI::Menu[:MenuTeleport].refresh(selected: currently_selected)
  end

  def current_location_data
    coords = ENTITY::GET_ENTITY_COORDS(teleport_entity,true)
    heading = ENTITY::GET_ENTITY_HEADING(teleport_entity)
    { x: coords.x, y: coords.y, z: coords.z, heading: heading }
  end

  def location_help(index)
    data = case index
      when :current then current_location_data
      when :waypoint then waypoint_data
      else TELEPORT_LOCATIONS.list_values("locations",index,[:x,:y,:z,:heading])
    end
    "Coordinates:\n"+
    "#{[data[:x],data[:y],data[:z]].map{|f| sprintf("%.3f",f) }.join(", ")}\n"+
    "Heading: #{data[:heading]}"
  end

  def teleport_entity
    entity = PLAYER::PLAYER_PED_ID()
    entity = PED::GET_VEHICLE_PED_IS_USING(entity) if PED::IS_PED_IN_ANY_VEHICLE(entity,false)
    entity
  end

  def teleport_to_index(index)
    data = TELEPORT_LOCATIONS.list_values("locations",index,[:x,:y,:z,:heading])
    ENTITY::SET_ENTITY_COORDS_NO_OFFSET(teleport_entity,data[:x],data[:y],data[:z],false,false,false)
    ENTITY::SET_ENTITY_HEADING(teleport_entity,data[:heading])
  end

  def rename_index(index)
    name = TELEPORT_LOCATIONS["locations.#{index}.name"]
    if name = get_keyboard_input(name)
      TELEPORT_LOCATIONS["locations.#{index}.name"] = name
      TELEPORT_LOCATIONS.write_to_file
      GUI::Menu.hide_submenu()
      GUI::Menu[:MenuTeleport].refresh()
    end
  end

  def delete_index(index)
    TELEPORT_LOCATIONS.list_delete("locations",index,[:name,:x,:y,:z,:heading])
    TELEPORT_LOCATIONS.write_to_file
    GUI::Menu.hide_submenu()
    GUI::Menu[:MenuTeleport].refresh()
  end

  def waypoint_data
    coords = waypoint_coordinates
    coords = [0.0,0.0] if !coords
    { x: coords[0], y: coords[1], z: 0.0, heading: 0.0 }
  end

  def waypoint_coordinates
    if blip = UI::GET_FIRST_BLIP_INFO_ID(BlipSprite::Waypoint)
      return UI::GET_BLIP_COORDS(blip)
    end
  end

  def teleport_to_waypoint
    if coords = waypoint_coordinates
      entity = PLAYER::PLAYER_PED_ID()
      entity = PED::GET_VEHICLE_PED_IS_USING(entity) if PED::IS_PED_IN_ANY_VEHICLE(entity,false)
      coords.z = -25.0
      until (gz = GAMEPLAY::GET_GROUND_Z_FOR_3D_COORD(*coords,false)) > 0.0 || coords.z > 800.0
        GTAV.wait(30)
        ENTITY::SET_ENTITY_COORDS(entity,*coords,false,false,false,true)
        gz = GAMEPLAY::GET_GROUND_Z_FOR_3D_COORD(*coords,false)
        coords.z += 25.0
      end
      coords.z = gz
      ENTITY::SET_ENTITY_COORDS(entity,*coords,false,false,false,true)
    end
  end

  def get_keyboard_input(default_value)
    GAMEPLAY::DISPLAY_ONSCREEN_KEYBOARD(0,"FMMC_KEY_TIP8","2",default_value,"","","",256)
    GTAV.wait(0) until GAMEPLAY::UPDATE_ONSCREEN_KEYBOARD() != 0
    value = GAMEPLAY::GET_ONSCREEN_KEYBOARD_RESULT()
    value == "" ? nil : value
  end

  GTAV.terminate_current_fiber!
end
