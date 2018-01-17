class MenuVehicleSpawner < GTAV::Script
end

GTAV.load_dir('.\mruby\scripts\menu_vehicle_spawner','*.rb')

class MenuVehicleSpawner

  def tick

    GTAV.wait(0)
    
    # Add button to main menu that opens our new menu
    GTAV[:RuntimeMenu].register_menu_item(:MenuVehicleSpawnerButton,
      type: :button,
      label: "Vehicle Spawner",
      expand: ->(i){ GUI::Menu.show(:MenuVehicleSpawnerCategories) }
     )

    # Terminate this fiber, our menu is registered and will execute in the main menu fiber
    GTAV.terminate_current_fiber!
  end



  MOD_TYPE_GXT_PREFIXES = {
     0 => "CMOD_SPO_",
     # 1 => "CMOD_BUM_",
     # 2 => "CMOD_BUM_",
     3 => "CMOD_SKI_",
     4 => "CMOD_EXH_",
    11 => "CMOD_ENG_",
    12 => "CMOD_BRA_",
    13 => "CMOD_GBX_",
    15 => "CMOD_SUS_",
    16 => "CMOD_ARM_",
  }

  HORN_IDS = [
    "CMOD_HRN_0",
    "CMOD_HRN_TRK",
  ]
  
  def colour_combination_collection(vehicle)
    max = VEHICLE::GET_NUMBER_OF_VEHICLE_COLOURS(vehicle)    
    collection = {}
    0.upto(max) do |i|
      VEHICLE::SET_VEHICLE_COLOUR_COMBINATION(vehicle,i)
      colours = [
        VEHICLE::GET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle),
        VEHICLE::GET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle),
      ]
      collection[i] = colours
    end
    collection
  end

  def vehicle_name_from_hash(hash)
    UI::_GET_LABEL_TEXT(VEHICLE::GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(GAMEPLAY::GET_HASH_KEY(hash)))
  end

  def favourites_add(options)
    # @@favourites << options
    next_slot = VEHICLE_SPAWNER.list_size("favourites","name")
    VEHICLE_SPAWNER["favourites.#{next_slot}.name"] = vehicle_name_from_hash(options[:model])
    VEHICLE_SPAWNER["favourites.#{next_slot}.data"] = options
    VEHICLE_SPAWNER.write_to_file
  end

  def favourites_update(options)
    options = options.dup
    index = options.delete(:favourites_index)
    # VEHICLE_SPAWNER["favourites.#{index}.name"] = name
    VEHICLE_SPAWNER["favourites.#{index}.data"] = options
    VEHICLE_SPAWNER.write_to_file
  end

  def favourites_delete(options)
    index = options[:favourites_index]
    VEHICLE_SPAWNER.list_delete(:favourites,index,[:name,:data])
    VEHICLE_SPAWNER.write_to_file
    log VEHICLE_SPAWNER.to_hash.inspect
  end
  
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
      if !dummy
        GAMEPLAY::CLEAR_AREA(*coords,size,false,false,false,false)
      end
      vehicle = VEHICLE::CREATE_VEHICLE(hash,*coords,0.0,true,true)
      ENTITY::SET_ENTITY_HEADING(vehicle,heading + 90.0)
      log "colours: #{VEHICLE::GET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle)}"
      log "colours: #{VEHICLE::GET_NUMBER_OF_VEHICLE_COLOURS(vehicle)}"
      log "colours: #{VEHICLE::GET_VEHICLE_COLOUR_COMBINATION(vehicle)}"
      if options
        options = options.dup
        options.delete(:model)
        tint = options.delete(:tint)
        colour_type = options.delete(:colour_type)
        colour_combination = options.delete(:colour_combination)
        colour_primary_rgb = options.delete(:colour_primary_rgb)
        colour_secondary_rgb = options.delete(:colour_secondary_rgb)
        VEHICLE::SET_VEHICLE_MOD_KIT(vehicle,0)
        case colour_type
        when :default
          VEHICLE::SET_VEHICLE_COLOUR_COMBINATION(vehicle,colour_combination)
        when :rgb
          VEHICLE::SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle,*colour_primary_rgb.rgb) if colour_primary_rgb
          VEHICLE::SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle,*colour_secondary_rgb.rgb) if colour_secondary_rgb
        end
        options.each_pair do |mod_type,mod_id|
          next if !mod_type.is_a?(Integer)
          log "SET_VEHICLE_MOD #{[vehicle,mod_type,mod_id,true].inspect}"
          VEHICLE::SET_VEHICLE_MOD(vehicle,mod_type,mod_id,false)
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

  def import_current_vehicle()
    vehicle = PED::GET_VEHICLE_PED_IS_USING(PLAYER::PLAYER_PED_ID())
    options = {}
    vehicle_hash = ENTITY::GET_ENTITY_MODEL(vehicle)
    options[:model] = VEHICLES_HASH_TO_NAME[vehicle_hash]
    options[:colour_combination] = 0
    options[:colour_type] = :rgb
    options[:colour_primary_rgb] = RGBA(*VEHICLE::GET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle),255)
    options[:colour_secondary_rgb] = RGBA(*VEHICLE::GET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle),255)
    log(options.inspect)
    options
  end
end

GTAV.spawn(:MenuVehicleSpawner)