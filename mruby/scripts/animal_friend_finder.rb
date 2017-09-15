
ANIMAL_HASH_01 = 4194021054 # bird ?
ANIMAL_HASH_02 = 3799318422 # cat ?

def draw_for_animal(ped,weapon,origin_coords)
  ped_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped,0.0,0.0,0.0)
  case weapon.to_i
  when 3799318422 # cat
    r,g,b = 0,255,0
    GRAPHICS::DRAW_LINE(*origin_coords,*ped_coords,r,g,b,255)
    if xy = GRAPHICS::_WORLD3D_TO_SCREEN2D(*ped_coords)
      # puts "xy: #{xy.inspect}"
      distance = GAMEPLAY::GET_DISTANCE_BETWEEN_COORDS(*origin_coords,*ped_coords,true)
      draw_text(*xy,"#{sprintf("%.1f",distance)}m")
    end
  else
    # puts "unknown hash #{weapon}"
  end
end

def gather_cats()
  puts "gather_cats()"
  player_group = PLAYER::GET_PLAYER_GROUP(PLAYER::PLAYER_ID())
  seat_once = false
  ($all_peds || []).each do |ped|
    if ENTITY::IS_ENTITY_A_PED(ped)
      weapon = WEAPON::GET_BEST_PED_WEAPON(ped,true)
      if weapon.to_i == 3799318422
        ENTITY::SET_ENTITY_INVINCIBLE(ped,true)
        puts "adding #{ped} to #{player_group}"
        PED::SET_PED_AS_GROUP_MEMBER(ped,player_group)
        PED::SET_PED_CAN_TELEPORT_TO_GROUP_LEADER(ped,player_group,true)
        PED::SET_GROUP_SEPARATION_RANGE(player_group,100.0)
        # if !seat_once
        #   seat_once = true
        #   AI::TASK_WARP_PED_INTO_VEHICLE(ped,PED::GET_VEHICLE_PED_IS_USING(PLAYER::PLAYER_PED_ID()),1)
        # end
      end
    end
  end
end

GTAV.register(:FriendFinder) do
  next_update_time = 0
  loop do
    if GTAV.time > next_update_time
      player_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER::PLAYER_PED_ID(),0.0,0.0,0.0)
      $all_peds = GTAV::world_get_all_peds().select do |ped|
        if ENTITY::IS_ENTITY_A_PED(ped) && PED::GET_PED_TYPE(ped) == 28
          # ped_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped,0.0,0.0,1.0)
          # weapon = WEAPON::GET_BEST_PED_WEAPON(ped,true)
          # puts "weapon : #{weapon}" if PED::GET_PED_TYPE(ped) == 28
          true
        else
          false
        end
      end
    end

    player_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER::PLAYER_PED_ID(),0.0,0.0,0.0)
    # origin_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER::PLAYER_PED_ID(),0.0,1.0,3.0)
    ($all_peds || []).each do |ped|
      if ENTITY::IS_ENTITY_A_PED(ped)
        weapon = WEAPON::GET_BEST_PED_WEAPON(ped,true)
        draw_for_animal(ped,weapon,player_coords)
      end
    end
    if GTAV.is_key_just_up(0x76) # F7
      gather_cats()
    end
    GTAV.wait(0)
  end
end