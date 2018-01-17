GTAV.register(:MenuTimeWeather) do
  GTAV.wait(0)
  
  $debug_inputs_draw = false
  $pressed_inputs = []
  GTAV[:RuntimeMenu].register_menu_item(:MenuTimeWeatherButton, label: "Time and Weather", type: :button, expand: ->(i){
    GUI::Menu.show(:MenuTimeWeather)
  })

  WeatherCollection = {
    "CLEAR"      => "CLEAR",
    "EXTRASUNNY" => "EXTRASUNNY",
    "CLOUDS"     => "CLOUDS",
    "RAIN"       => "RAIN",
    "CLEARING"   => "CLEARING",
    "THUNDER"    => "THUNDER",
    "SMOG"       => "SMOG",
    "FOGGY"      => "FOGGY",
    "XMAS"       => "XMAS",
    "SNOWLIGHT"  => "SNOWLIGHT",
    "BLIZZARD"   => "BLIZZARD",
  }

  MenuTimeWeather = GUI::Menu.new({ id: :MenuTimeWeather })  
  def MenuTimeWeather.items
    items = []
    items << { type: :header, title: "Time/Weather" }
    items << { type: :select, label: "Weather", id: :weather,
      collection: WeatherCollection,
      default: "CLEAR",
      change: lambda{|i| GTAV[:MenuTimeWeather].set_weather(i.value) }
    }
    items
  end

  def set_weather(value)
    GAMEPLAY::SET_WEATHER_TYPE_NOW(value)
  end

  GTAV.terminate_current_fiber!
end
