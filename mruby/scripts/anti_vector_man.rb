
$avm_entities = QueueSet.new(32)
# $avm_entities = []

GTAV.register(:AVM,true) do
  loop do
    player_ped_id = PLAYER::PLAYER_PED_ID()
    player_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_ped_id,0.0,0.0,0.0)
    force_pow = 2.2
    force_div = 100.0
    button = 77

    player_vehicle = PED::GET_VEHICLE_PED_IS_USING(player_ped_id)
    if player_vehicle
      player_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_ped_id,0.0,5.0,0.0)
      force_div = 25.0
      button = 68
    end

    do_force = false
    do_force = true  if !WEAPON::IS_PED_ARMED(PLAYER::PLAYER_ID(),7) && CONTROLS::IS_CONTROL_PRESSED(20,button)

    # puts "armed: #{!WEAPON::IS_PED_ARMED(PLAYER::PLAYER_ID(),7)}"
    # puts "controls: #{CONTROLS::GET_CONTROL_VALUE(20,77)}"

    ($avm_entities.to_a || []).each do |vehicle|
      entity_type = nil
      entity_type = :vehicle if ENTITY::IS_ENTITY_A_VEHICLE(vehicle) && vehicle != player_vehicle.to_i
      entity_type = :ped if ENTITY::IS_ENTITY_A_PED(vehicle) && vehicle != player_ped_id.to_i

      if entity_type
        vehicle_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle,0.0,0.0,0.0)
        distance = GAMEPLAY::GET_DISTANCE_BETWEEN_COORDS(*player_coords,*vehicle_coords,true)

        if distance < 10.0
          dx = player_coords.x - vehicle_coords.x
          dy = player_coords.y - vehicle_coords.y

          dyy = ((10.0 - distance) ** force_pow) / force_div
          dxx = ((10.0 - distance) ** force_pow) / force_div

          dx *= -1
          dy *= -1

          # if xy = GRAPHICS::_WORLD3D_TO_SCREEN2D(*vehicle_coords)
          #   draw_text(*xy,"#{sprintf("%.3f",dxx)},#{sprintf("%.3f",dyy)}")
          # end
          if do_force
            PED::SET_PED_TO_RAGDOLL(vehicle,1000,1000,0,false,false,false) if entity_type == :ped
            ENTITY::APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(vehicle,1,dx*dxx,dy*dyy,0.0,true,false,true,true)
            # r,g,b = 255,0,0
            # GRAPHICS::DRAW_LINE(*player_coords,*vehicle_coords,r,g,b,255)
          end
          $avm_entities.push(vehicle)
        elsif distance > 50.0
          $avm_entities.delete(vehicle)
        end

      end
    end

    GTAV.wait(0)
  end
end

GTAV.register(:AVMUpdater,true) do
  ticks = 9999
  cp = nil
  loop do
    GTAV.wait(0)
    cp = ENTITY::GET_ENTITY_COORDS(PLAYER::PLAYER_PED_ID(),false)
    ents = GTAV::world_get_all_vehicles()
    ents += GTAV::world_get_all_peds()
    ents.each do |ent|
      ticks += 1
      if ticks > 5
        ticks = 0
        GTAV.wait(0)
        cp = ENTITY::GET_ENTITY_COORDS(PLAYER::PLAYER_PED_ID(),false)
      end
      ce = ENTITY::GET_ENTITY_COORDS(ent,false)
      # puts "#{PLAYER::PLAYER_PED_ID()},#{ENTITY::GET_ENTITY_COORDS(PLAYER::PLAYER_PED_ID(),false)},#{cp.inspect},#{ce.inspect}"
      distance = SYSTEM::VDIST(*cp,*ce)
      if distance < 50.0
        $avm_entities.push(ent)
      end
    end
  end
end

# GTAV.register(:AVMUpdater,true) do
#   next_vehicle_update = 0
#   next_ped_update = 0

#   loop do
#     time = GTAV.time
#     player_coords = ENTITY::GET_ENTITY_COORDS(PLAYER::PLAYER_PED_ID(),false)
#     $avm_entities = []
#     $avm_entities += GTAV::world_get_all_vehicles().select do |vehicle|
#       vehicle_coords = ENTITY::GET_ENTITY_COORDS(vehicle,false)
#       distance = SYSTEM::VDIST(*player_coords,*vehicle_coords)
#       distance < 50.0
#     end
#     if time > next_ped_update
#       next_ped_update = time + 1000
#       $avm_entities += GTAV::world_get_all_peds().select do |ped|
#         ped_coords = ENTITY::GET_ENTITY_COORDS(ped,false)
#         # distance = GAMEPLAY::GET_DISTANCE_BETWEEN_COORDS(*player_coords,*ped_coords,true)
#         distance = SYSTEM::VDIST(*player_coords,*ped_coords)
#         distance < 50.0
#       end
#     end
#     puts "got #{$avm_entities.size}"
#     GTAV.wait(500)
#   end
# end
