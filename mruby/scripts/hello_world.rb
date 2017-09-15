# GTAV.load("./mruby/load_test.rb")

class HelloWorld < GTAV::Script
  def initialize
    puts "HelloWorld#initialize"
  end
  def call
    # if GTAV.is_key_just_up(0x79) # VK_F10
    if true
      player_id, player_ped_id = PLAYER::PLAYER_ID(), PLAYER::PLAYER_PED_ID()
      # puts "player_id: #{player_id.inspect}, player_ped_id: #{player_ped_id.inspect}"
      coords1 = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_ped_id,-3.0,5.0,1.0)
      coords2 = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_ped_id,3.0,5.0,3.0)
      # puts "#{coords1.inspect},#{coords2.inspect}"
      # GRAPHICS::SET_DEBUG_LINES_AND_SPHERES_DRAWING_ACTIVE(true)
      GRAPHICS::DRAW_LINE(*coords1,*coords2,0,255,0,255)

      # puts PED::STOP_ANY_PED_MODEL_BEING_SUPPRESSED().inspect
      # puts "last vehicle #{PLAYER::GET_PLAYERS_LAST_VEHICLE().inspect}"
      # puts "this vehicle #{PED::GET_VEHICLE_PED_IS_USING(player_ped_id).inspect}"
      # puts "health: #{PED::GET_PED_MAX_HEALTH(player_ped_id).inspect}"

      # puts PED::SET_PED_GET_OUT_UPSIDE_DOWN_VEHICLE(player_ped_id,2).inspect
    # File.open("write_test","w"){|f| f << "hello"}

    else
      # GRAPHICS::SET_DEBUG_LINES_AND_SPHERES_DRAWING_ACTIVE(false)
    end

    if GTAV.is_key_just_up(0x77) #F8
      model = "ADDER"
      hash = GAMEPLAY::GET_HASH_KEY(model)
      if STREAMING::IS_MODEL_IN_CDIMAGE(hash) && STREAMING::IS_MODEL_A_VEHICLE(hash)
        STREAMING::REQUEST_MODEL(hash)
        GTAV.wait(0) until STREAMING::HAS_MODEL_LOADED(hash)
        coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER::PLAYER_PED_ID(),0.0,5.0,1.0)
        vehicle = VEHICLE::CREATE_VEHICLE(hash,*coords,0.0,true,true)
        puts "vehicle: #{vehicle.inspect}"
        GTAV.wait(1000)
        STREAMING::SET_MODEL_AS_NO_LONGER_NEEDED(hash)
        # ENTITY::SET_VEHICLE_AS_NO_LONGER_NEEDED(vehicle)
        VEHICLE::DELETE_VEHICLE(vehicle)
      end
    end
    
  end
end



def distance(a,b)
  if a > b
    a - b
  else
    b - a
  end
end


GTAV.register(:HelloWorld) do
  loop do
    player_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER::PLAYER_PED_ID(),0.0,0.0,0.0)
    origin_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER::PLAYER_PED_ID(),0.0,1.0,3.0)
    start = GTAV.time
    ($all_vehicles || []).each do |vehicle|
      if ENTITY::IS_ENTITY_A_VEHICLE(vehicle)
        vehicle_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle,0.0,0.0,1.0)
        GRAPHICS::DRAW_LINE(*player_coords,*vehicle_coords,0,255,0,255)
      end
    end

    GTAV.wait(0)
  end
end
GTAV.register(:HelloWorld2) do
  loop do
    player_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER::PLAYER_PED_ID(),0.0,0.0,0.0)
    origin_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER::PLAYER_PED_ID(),0.0,1.0,3.0)
    start = GTAV.time
    ($all_vehicles || []).each do |vehicle|
      if ENTITY::IS_ENTITY_A_VEHICLE(vehicle)
        vehicle_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle,0.0,0.0,1.0)
        GRAPHICS::DRAW_LINE(*player_coords,*vehicle_coords,0,255,0,255)
      end
    end

    GTAV.wait(0)
  end
end

GTAV.register(:HelloWorldUpdater) do
  loop do
    player_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER::PLAYER_PED_ID(),0.0,0.0,0.0)
    $all_vehicles = GTAV::world_get_all_vehicles().select do |vehicle|
      if ENTITY::IS_ENTITY_A_VEHICLE(vehicle)
        vehicle_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle,0.0,0.0,1.0)
        distance = GAMEPLAY::GET_DISTANCE_BETWEEN_COORDS(*player_coords,*vehicle_coords,true)
        if distance < 100.0
          true
        else
          false
          # true
        end
      else
        false
        # true
      end
    end
    GTAV.wait(1000)
  end
end
