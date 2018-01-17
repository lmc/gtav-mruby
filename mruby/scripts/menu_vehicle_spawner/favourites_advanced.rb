
class MenuVehicleSpawner

  MenuVehicleSpawnerFavouritesAdvanced = GUI::Menu.new({ id: :MenuVehicleSpawnerFavouritesAdvanced })

  MenuVehicleSpawnerFavouritesAdvanced.items do |items|
    items << { type: :header , title: "", title_bg: false, subtitle: "#{MenuVehicleSpawnerFavouritesAdvanced.values[:name]}" }
    # items << { type: :button , label: "Rename" ,
    #   action: lambda{|i|  }
    # }
    items << { type: :button , label: "Edit" ,
      action: lambda{|i| GUI::Menu.show(:MenuVehicleSpawnerAdvanced, selected: 0, values: i.menu.values) }
    }
    items << { type: :button , label: "Delete" ,
      action: lambda{|i| GTAV[:MenuVehicleSpawner].favourites_delete(i.menu.values); GUI::Menu.show(:MenuVehicleSpawnerFavourites, selected: 0) }
    }
    items << {type: :help, default: ->(i){ i.menu.values.inspect} }
  end

  def MenuVehicleSpawnerFavouritesAdvanced.on_nav_left_pressed
    GUI::Menu.hide_submenu()
  end
  def MenuVehicleSpawnerFavouritesAdvanced.on_nav_back_pressed
    GUI::Menu.hide_submenu()
  end

end