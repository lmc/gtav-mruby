
class MenuVehicleSpawner

  MenuVehicleSpawner = GUI::Menu.new( id: :MenuVehicleSpawner , w: 0.2 )

  # called once to construct the list of items, supports scrolling
  MenuVehicleSpawner.items do |items|
    items << { type: :header , title: "#{CATEGORIES[MenuVehicleSpawner.values[:category]]}", subtitle: "" }
    # Add a button for each filename/label in the list
    @@categories[MenuVehicleSpawner.values[:category]].each do |name|
      label = name
      items << {
        type: :button,
        label: lambda{|i| "#{GTAV[:MenuVehicleSpawner].vehicle_name_from_hash(i.id)}"},
        id: name,
        # enabled: lambda{|i| STREAMING::IS_MODEL_IN_CDIMAGE(GAMEPLAY::GET_HASH_KEY(i.id)) },
        action: lambda{|i| GTAV[:MenuVehicleSpawner].spawn_vehicle(i.id) },
        action_name: "Spawn",
        help: lambda{|i| GTAV[:MenuVehicleSpawner].vehicle_help_text(i.id) },
        # right_action: lambda{|i| GUI::Menu.show_submenu(:MenuVehicleSpawnerAdvanced, values: { model: i.id }, selected: 0) },
        expand: lambda{|i| GUI::Menu.show(:MenuVehicleSpawnerAdvanced, values: { model: i.id, categories_index: MenuVehicleSpawner.values[:category]}, selected: 0) },
        expand_name: "Customise",
      }
    end
    items << { type: :help }
  end
  
  def MenuVehicleSpawner.on_nav_back_pressed
    GUI::Menu.show(:MenuVehicleSpawnerCategories)
  end

end