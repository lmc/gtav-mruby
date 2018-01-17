
class MenuVehicleSpawner

  @@categories = Hash.new{|h,k| h[k] = []}
  CATEGORIES = {
     0 => "Compacts",
     1 => "Sedans",
     2 => "SUVs",
     3 => "Coupes",
     4 => "Muscle",
     5 => "Sports Classics",
     6 => "Sports",
     7 => "Super",
     8 => "Motorcycles",
     9 => "Off-road",
    10 => "Industrial",
    11 => "Utility",
    12 => "Vans",
    13 => "Cycles",
    14 => "Boats",
    15 => "Helicopters",
    16 => "Planes",
    17 => "Service",
    18 => "Emergency",
    19 => "Military",
    20 => "Commercial",
    21 => "Trains",
  }

  VEHICLE_SPAWNER = []
  VEHICLE_SPAWNER = PersistentHash.new('.\mruby\config\vehicle_spawner.config.rb',nil,"VEHICLE_SPAWNER")
  if VEHICLE_SPAWNER.size == 0
    VEHICLE_SPAWNER["favourites.0.name"] = "Test"
    VEHICLE_SPAWNER["favourites.0.data"] = {model: "bullet"}
    VEHICLE_SPAWNER.write_to_file
  end

  # Define our new menu
  MenuVehicleSpawnerCategories = GUI::Menu.new( id: :MenuVehicleSpawnerCategories , w: 0.2, parent: :RuntimeMenu )

  # called once to construct the list of items, supports scrolling
  MenuVehicleSpawnerCategories.items do |items|
    items << { type: :header , title: "Vehicles", subtitle: "Categories" }

    items << {
      type: :button,
      label: "Favourites",
      help:  "#{VEHICLE_SPAWNER.list_size(:favourites,:name)} vehicles",
      id: :favourites,
      # action: ->(i){ GUI::Menu.show_submenu(:MenuVehicleSpawnerFavourites, selected: 0) },
      # right_action: ->(i){ GUI::Menu.show_submenu(:MenuVehicleSpawnerFavourites, selected: 0 },
      # action: ->(i){ GUI::Menu.show(:MenuVehicleSpawnerFavourites, selected: 0) },
      expand: ->(i){ GUI::Menu.show(:MenuVehicleSpawnerFavourites, selected: 0) },
    }

    items << {
      type: :button,
      label: "Import current vehicle",
      help:  "  ?",
      id: :import,
      enabled: ->(i){ PED::GET_VEHICLE_PED_IS_USING(PLAYER::PLAYER_PED_ID()) },
      # action: ->(i){ GUI::Menu.show(:MenuVehicleSpawnerAdvanced, selected: 0, values: GTAV[:MenuVehicleSpawner].import_current_vehicle()) },
      expand: ->(i){ GUI::Menu.show(:MenuVehicleSpawnerAdvanced, selected: 0, values: GTAV[:MenuVehicleSpawner].import_current_vehicle()) },
    }

    if @@categories.size == 0
      ALL_VEHICLES.each do |vehicle_name|
        vehicle_class = VEHICLE::GET_VEHICLE_CLASS_FROM_NAME(GAMEPLAY::GET_HASH_KEY(vehicle_name))
        @@categories[vehicle_class] << vehicle_name
      end
    end

    @@categories.keys.sort.each_with_index do |category,index|
      items << {
        type: :button,
        label: "#{CATEGORIES[category]}",
        help:  "#{@@categories[category].size} vehicles",
        id: category,
        # action: ->(i){ GUI::Menu.show_submenu(:MenuVehicleSpawner, selected: 0, values: {category: i.id}) },
        # right_action: ->(i){ GUI::Menu.show_submenu(:MenuVehicleSpawner, selected: 0, values: {category: i.id}) },
        action: ->(i){ GUI::Menu.show(:MenuVehicleSpawner, selected: 0, values: {category: i.id}) },
        expand: ->(i){ GUI::Menu.show(:MenuVehicleSpawner, selected: 0, values: {category: i.id}) },
      }
    end

    items << { type: :help, default: lambda{|i| i.menu.values.inspect } }
  end
  
  # open main menu when back is pressed
  # def MenuVehicleSpawnerCategories.on_nav_back_pressed
  #   GUI::Menu.show(:RuntimeMenu)
  # end

end