
class MenuVehicleSpawner


  ColourTypeCollection = {
    random:  "Random",
    default: "Factory",
    rgb:     "RGB",
  }
  
  WindowTintCollection = {}  
  VehicleWindowTint.constants.each{|key| WindowTintCollection[ VehicleWindowTint.const_get(key) ] = key.to_s}

  # Define our new menu
  MenuVehicleSpawnerAdvanced = GUI::Menu.new( id: :MenuVehicleSpawnerAdvanced , w: 0.325 , max_rows: 18 )

  # called once to construct the list of items, supports scrolling
  MenuVehicleSpawnerAdvanced.items do |items|
    values = MenuVehicleSpawnerAdvanced.values
    model = values[:model]
    dummy = GTAV[:MenuVehicleSpawner].spawn_vehicle(model,true)
    VEHICLE::SET_VEHICLE_MOD_KIT(dummy,0)
    GTAV.wait(0)
    spawnl = lambda{|i| GTAV[:MenuVehicleSpawner].spawn_vehicle(i.menu.values[:model],false,i.menu.values)}
    if values[:favourites_index]
      items << { type: :header, label: "#{VEHICLE_SPAWNER.list_value(:favourites,values[:favourites_index],:name)}", subtitle: "Editing favourite" }
    else
      items << { type: :header, label: "#{GTAV[:MenuVehicleSpawner].vehicle_name_from_hash(model)}", subtitle: "ADVANCED" }
    end
    items << { type: :select, label: "Colour Type", id: :colour_type, default: :random, collection: ColourTypeCollection, action: spawnl }
    items << { type: :select, label: "Factory Colours", id: :colour_combination, default: 0, collection: GTAV[:MenuVehicleSpawner].colour_combination_collection(dummy), enabled: ->(i){ i.menu.values[:colour_type] == :default}, action: spawnl }
    items << { type: :colour, label: "Primary Colour RGB", id: :colour_primary_rgb, default: RGBA(192,128,128,255), enabled: ->(i){ i.menu.values[:colour_type] == :rgb}, action: spawnl }
    items << { type: :colour, label: "Secondary Colour RGB", id: :colour_secondary_rgb, default: RGBA(25,128,255,255), enabled: ->(i){ i.menu.values[:colour_type] == :rgb}, action: spawnl }
    enum_to_hash(VehicleMod).each_pair do |mod_type,label|
      count = VEHICLE::GET_NUM_VEHICLE_MODS(dummy,mod_type)
      next if count <= 0
      collection = {}
      0.upto(count) do |i|
        gxt = VEHICLE::GET_MOD_TEXT_LABEL(dummy,mod_type,i)
        gxt = nil if gxt == "" || gxt == "NULL"
        gxt ||= case mod_type
        when 11
          i == 0 ? nil : "#{MOD_TYPE_GXT_PREFIXES[mod_type]}#{i+1}"
        when 14
          "#{HORN_IDS[i]}"
        else
          MOD_TYPE_GXT_PREFIXES[mod_type] ? "#{MOD_TYPE_GXT_PREFIXES[mod_type]}#{i}" : nil
        end
        gxt = nil if gxt == "" || gxt == "NULL"
        collection[i] = gxt ? UI::_GET_LABEL_TEXT(gxt) : "#{i}"
      end
      gxt = VEHICLE::GET_MOD_SLOT_NAME(dummy,mod_type)
      gxt = nil if gxt == ""
      # items << { type: :select , label: "#{label} - #{mod_type} = #{count}", id: mod_type, collection: collection, default: collection.keys[0] }
      items << {
        type: :select,
        label: "#{gxt || label}",
        id: mod_type,
        collection: collection,
        default: collection.keys[0],
        action: spawnl,
        action_name: "Spawn",
      }
    end
    VEHICLE::DELETE_VEHICLE(dummy)
    items << {
      type: :select,
      label: "Window tint",
      id: :tint,
      collection: enum_to_hash(VehicleWindowTint),
      default: VehicleWindowTint::Stock
    }
    if values[:favourites_index]
      items << {
        type: :button ,
        label: "Save",
        action: lambda{|i| GTAV[:MenuVehicleSpawner].favourites_update(i.menu.values); GUI::Menu.show(:MenuVehicleSpawnerFavourites, selected: i.menu.values[:favourites_index] + 1) }
      }
    else
      items << {
        type: :button ,
        label: "Spawn",
        action: lambda{|i| GTAV[:MenuVehicleSpawner].spawn_vehicle(i.menu.values[:model],false,i.menu.values)}
      }
      items << {
        type: :button ,
        label: "Add to favourites",
        action: lambda{|i| GTAV[:MenuVehicleSpawner].favourites_add(i.menu.values)}
      }
    end
    items << { type: :help, default: lambda{|i| i.menu.values.inspect } }
  end
  
  # open main menu when back is pressed
  def MenuVehicleSpawnerAdvanced.on_nav_back_pressed
    values = MenuVehicleSpawnerAdvanced.values
    if favourites_index = values[:favourites_index]
      GUI::Menu.show(:MenuVehicleSpawnerFavourites, selected: favourites_index)
      GUI::Menu.show_submenu(:MenuVehicleSpawnerFavouritesAdvanced, selected: 1)
    elsif categories_index = values[:categories_index]
      GUI::Menu.show(:MenuVehicleSpawner, selected: @@categories[categories_index].index(values[:model]) + 1, values: {category: categories_index})
    else
      GUI::Menu.show(:MenuVehicleSpawnerCategories, selected: 2)
    end
  end

end