GTAV.register(:MenuVehicleSpawner) do

  GTAV.wait(0)
  
  # Add button to main menu that opens our new menu
  GTAV[:RuntimeMenu].register_menu_item(:MenuVehicleSpawnerButton,
    type: :button,
    label: "Vehicle Spawner"
   ) do |item|
    UiMenu.show(:MenuVehicleSpawner)
  end

  VEHICLES = {
    "BULLET" => "Bullet",
    "ELEGY"  => "Elegy Classic",
    "ELEGY2"  => "Elegy",
    "COMET2"  => "Comet 2",
    "COMET"  => "Comet",
  }
  
  # actually spawn a vehicle given it's model filename
  def spawn_vehicle(model,dummy = false,options = {})
    hash = GAMEPLAY::GET_HASH_KEY(model)
    if STREAMING::IS_MODEL_IN_CDIMAGE(hash) && STREAMING::IS_MODEL_A_VEHICLE(hash)
      STREAMING::REQUEST_MODEL(hash)
      GTAV.wait(0) until STREAMING::HAS_MODEL_LOADED(hash)
      bounds0, bounds1 = GAMEPLAY::GET_MODEL_DIMENSIONS(hash)
      size = bounds1.y - bounds0.y
      if dummy
        coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER::PLAYER_PED_ID(),0.0,5.0,100.0)
      else
        coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER::PLAYER_PED_ID(),0.0,5.0,1.0)
      end
      heading = ENTITY::GET_ENTITY_HEADING(PLAYER::PLAYER_PED_ID())
      GAMEPLAY::CLEAR_AREA(*coords,size,false,false,false,false)
      vehicle = VEHICLE::CREATE_VEHICLE(hash,*coords,0.0,true,true)
      ENTITY::SET_ENTITY_HEADING(vehicle,heading + 90.0)
      if options
        options = options.dup
        options.delete(:model)
        tint = options.delete(:tint)
        VEHICLE::SET_VEHICLE_MOD_KIT(vehicle,0)
        options.each_pair do |mod_type,mod_id|
          log "SET_VEHICLE_MOD #{[vehicle,mod_type,mod_id,true].inspect}"
          VEHICLE::SET_VEHICLE_MOD(vehicle,mod_type,mod_id,true)
        end
      end
      STREAMING::SET_MODEL_AS_NO_LONGER_NEEDED(hash)
      if !dummy
        ENTITY::SET_VEHICLE_AS_NO_LONGER_NEEDED(vehicle)
      end
      return vehicle
    end
    return nil
  end

  def vehicle_help_text(model)
<<-TEXT
#{model}
#{VEHICLES[model]}
TEXT
  end

  # Define our new menu
  MenuVehicleSpawner = UiMenu.new({
    id: :MenuVehicleSpawner,
  })

  # called once to construct the list of items, supports scrolling
  def MenuVehicleSpawner.items
    items = []
    items << { type: :header , label: "Car Spawner", label_sub: "" }
    # Add a button for each filename/label in the list
    VEHICLES.each_pair do |name,label|
      items << {
        type: :button,
        label: label,
        id: name,
        action: lambda{|i| GTAV[:MenuVehicleSpawner].spawn_vehicle(i.id) },
        help: lambda{|i| GTAV[:MenuVehicleSpawner].vehicle_help_text(i.id) },
        right_action: lambda{|i| UiMenu.show_submenu(:MenuVehicleSpawnerAdvanced, values: { model: i.id }, selected: 0) },
      }
    end
    items << { type: :help }
    items
  end
  
  # open main menu when back is pressed
  def MenuVehicleSpawner.on_nav_back_pressed
    UiMenu.show(:RuntimeMenu)
  end
  
  WindowTintCollection = {}  
  VehicleWindowTint.constants.each{|key| WindowTintCollection[ VehicleWindowTint.const_get(key) ] = key.to_s}

  # Define our new menu
  MenuVehicleSpawnerAdvanced = UiMenu.new({
    id: :MenuVehicleSpawnerAdvanced,
  })

  # called once to construct the list of items, supports scrolling
  def MenuVehicleSpawnerAdvanced.items
    dummy = GTAV[:MenuVehicleSpawner].spawn_vehicle(values[:model],true)
    VEHICLE::SET_VEHICLE_MOD_KIT(dummy,0)
    GTAV.wait(0)
    items = []
    items << { type: :header , label: "#{VEHICLES[values[:model]]}", label_sub: "ADVANCED" }
    enum_to_hash(VehicleMod).each_pair do |mod_type,label|
      count = VEHICLE::GET_NUM_VEHICLE_MODS(dummy,mod_type)
      next if count <= 0
      collection = {}
      0.upto(count) do |i|
        gxt = VEHICLE::GET_MOD_TEXT_LABEL(dummy,mod_type,i)
        collection[i] = gxt == "" ? "#{i}" : UI::_GET_LABEL_TEXT(gxt)
      end
      # items << { type: :select , label: "#{label} - #{mod_type} = #{count}", id: mod_type, collection: collection, default: collection.keys[0] }
      items << { type: :select , label: "#{label}", id: mod_type, collection: collection, default: collection.keys[0] }
    end
    VEHICLE::DELETE_VEHICLE(dummy)
    items << { type: :select , label: "Window tint", id: :tint, collection: enum_to_hash(VehicleWindowTint), default: VehicleWindowTint::Stock }
    items << { type: :button , label: "Spawn", action: lambda{|i| GTAV[:MenuVehicleSpawner].spawn_vehicle(i.menu.values[:model],false,i.menu.values)} }
    items << { type: :help, default: lambda{|i| i.menu.values.inspect } }
    items
  end
  
  # open main menu when back is pressed
  def MenuVehicleSpawnerAdvanced.on_nav_back_pressed
    UiMenu.hide_submenu()
  end
  
  # Terminate this fiber, our menu is registered and will execute in the main menu fiber
  GTAV.terminate_current_fiber!
end