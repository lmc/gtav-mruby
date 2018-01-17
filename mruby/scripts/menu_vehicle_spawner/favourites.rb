
class MenuVehicleSpawner

  MenuVehicleSpawnerFavourites = GUI::Menu.new( id: :MenuVehicleSpawnerFavourites , w: 0.2 , parent: :MenuVehicleSpawnerCategories )

  # called once to construct the list of items, supports scrolling
  MenuVehicleSpawnerFavourites.items do |items|
    items << { type: :header , label: "Favourites", label_sub: "" }
    favourites_size = VEHICLE_SPAWNER.list_size(:favourites,:name)
    VEHICLE_SPAWNER.each_list(:favourites,[:name,:data]) do |params,index|
      items << {
        type: :button,
        label: lambda{|i| "#{params[:name]}"},
        id: params[:model],
        # enabled: lambda{|i| STREAMING::IS_MODEL_IN_CDIMAGE(GAMEPLAY::GET_HASH_KEY(i.id)) },
        action: lambda{|i| GTAV[:MenuVehicleSpawner].spawn_vehicle(params[:data][:model],false,params[:data]) },
        help: lambda{|i| "help" },
        expand: lambda{|i| GUI::Menu.show_submenu(:MenuVehicleSpawnerFavouritesAdvanced, values: params[:data].merge(favourites_index: index), selected: 0) },
        # right_action: lambda{|i| GUI::Menu.show(:MenuVehicleSpawnerAdvanced, values: { model: i.id }, selected: 0) },
      }
    end
    items << { type: :help }
  end
  
  def MenuVehicleSpawnerFavourites.on_nav_back_pressed
    GUI::Menu.show(:MenuVehicleSpawnerCategories)
  end

end