
$avm_entities = QueueSet.new(128)
# $avm_entities = QueueSet.new(64)

EXCITING_OBJECTS = [
  GAMEPLAY::GET_HASH_KEY("VEHICLE_WEAPON_TANK"),
  GAMEPLAY::GET_HASH_KEY("WEAPON_VEHICLE_ROCKET"),
  GAMEPLAY::GET_HASH_KEY("WEAPON_PASSENGER_ROCKET"),
  GAMEPLAY::GET_HASH_KEY("WEAPON_AIRSTRIKE_ROCKET"),
  GAMEPLAY::GET_HASH_KEY("WEAPON_AIRSTRIKE_ROCKET"),
  GAMEPLAY::GET_HASH_KEY("WEAPON_FLARE"),
  258_697_0039,
  
]
EXCITING_OBJECTS_HASH = ::Hash[ EXCITING_OBJECTS.map{|k| [k,true]} ]
log EXCITING_OBJECTS_HASH.inspect
GTAV.register(:AVM,true) do
  GTAV.wait(0)

  $excitement_script = false
  $bullet_script = false
  $excitement = false
  $excitement_object = false

  @enabled = false
  @radius = 20.0
  # @exponent = 10.9
  @exponent = 12.9
  @divisor = 1.0
  def enabled; @enabled; end
  def enabled=(v); @enabled = v; end
  def radius; @radius; end
  def radius=(v); @radius = v; end
  def exponent; @exponent; end
  def exponent=(v); @exponent = v; end
  def divisor; @divisor; end
  def divisor=(v); @divisor = v; end

  @control_in_vehicle = Control::VehicleAim
  @control_on_foot = Control::Aim

  AvmMenu = GUI::Menu.new({ id: :AvmMenu , parent: :RuntimeMenu })
  AvmMenu.items do |items|
    items << { type: :header   , label: "Personal Space" }
    items << {
      type: :checkbox,
      id: :enabled,
      label: "Enabled",
      change: ->(i){
        GTAV[:AVM].enabled = i.value
      },
      default: GTAV[:AVM].enabled
    }
    items << {
      type: :float,
      id: :radius,
      label: "Radius",
      change: ->(i){
        log "changed"
        GTAV[:AVM].radius = i.value
      },
      default: GTAV[:AVM].radius,
      min: 1.0,
      max: 50.0,
      step: 0.1,
    }
    items << {
      type: :float,
      id: :exponent,
      label: "Exponent",
      change: ->(i){
        GTAV[:AVM].exponent = i.value
      },
      default: GTAV[:AVM].exponent,
      min: 1.0,
      max: 50.0,
      step: 0.01,
    }
    items << {
      type: :float,
      id: :divisor,
      label: "Divisor",
      change: ->(i){
        GTAV[:AVM].divisor = i.value
      },
      default: GTAV[:AVM].divisor,
      min: 1.0,
      max: 50.0,
      step: 0.01,
    }
    items << {
      type: :checkbox,
      id: :bullets,
      label: "Deflect bullets",
      change: ->(i){
        $bullet_script = i.value
      },
      default: $bullet_script
    }
    items << {
      type: :checkbox,
      id: :projectiles,
      label: "Deflect projectiles",
      change: ->(i){
        $excitement_script = i.value
      },
      default: $excitement_script
    }
    items << {
      type: :list,
      id: :control_on_foot,
      label: "Control (on foot)",
      change: ->(i){
        @control_on_foot = i.value
      },
      default: @control_on_foot,
      collection: enum_to_hash(Control),
    }
    items << {
      type: :list,
      id: :control_in_vehicle,
      label: "Control (vehicle)",
      change: ->(i){
        @control_in_vehicle = i.value
      },
      default: @control_in_vehicle,
      collection: enum_to_hash(Control),
    }
    items << { type: :help , default: ->(i){ i.menu.values.inspect[-50..-1] } }
  end

  GTAV[:RuntimeMenu].register_menu_item(:AVMEnabled,
    label: "Personal Space System",
    type: :button,
    default: @enabled,
    expand: ->(i){
      GUI::Menu.show(:AvmMenu)
    }
  )


  # GTAV[:RuntimeMenu].register_menu_item(:AVMRadius, label: "PSS Radius", type: :float, min: 1.0, max: 50.0, step: 0.1, default: @radius) do |item|
  #   GTAV[:AVM].radius = item.value
  # end

  ANNOYING_OBJECTS = [
    3231494328, # light posts that never unroot
    3639322914,
    2674143992,
    491238953,
    1191039009,
    8628711082
]

  EXPLOSIONED_ENTITIES = QueueSet.new(128)
  MOVED_ENTITIES = QueueSet.new(128)
  PRIORITY_ENTITIES = QueueSet.new(8)
  explosions = []
  big_explosions = []
  explosions_this_tick = false

  loop do

    if @enabled

      $excitement = false
      
      explosions_this_tick = explosions.size > 0
      
      player_ped_id = PLAYER::PLAYER_PED_ID()
      player_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_ped_id,0.0,0.0,0.0)
      # player_coords_orig = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_ped_id,0.0,0.0,0.0)
      button = @control_on_foot
      player_coords_orig_vehicle = nil

      offset = GTAV::Vector3.new(0.0,0.0,0.0)
      player_vehicle = PED::GET_VEHICLE_PED_IS_USING(player_ped_id)
      ENTITY::SET_ENTITY_PROOFS(player_ped_id,false,true,true,false,false,false,false,false)
      if player_vehicle
        b1,b2 = GAMEPLAY::GET_MODEL_DIMENSIONS(ENTITY::GET_ENTITY_MODEL(player_vehicle))
        offset.y = b2.y
        # player_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_vehicle,*offset)
        player_coords_orig_vehicle_o = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_vehicle,0.0,0.0,0.0)
        player_coords_orig_vehicle = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_vehicle,*offset)
        button = @control_in_vehicle
        # OBJECT::SET_OBJECT_PHYSICS_PARAMS(player_vehicle,100000.0,1.0,1.0,1.0,1.0,  100.0,100.0,100.0,100.0,1.0,1.0)
        ENTITY::SET_ENTITY_PROOFS(player_vehicle,false,true,true,false,false,false,false,false)
      end

      frame_time = GAMEPLAY::GET_FRAME_TIME()

      do_force = false
      do_force = true  if !WEAPON::IS_PED_ARMED(PLAYER::PLAYER_ID(),7) && CONTROLS::IS_CONTROL_PRESSED(0,button)

      if do_force || $excitement_object

        # all_ents = PRIORITY_ENTITIES.array + $avm_entities.array
        
        $avm_entities.array.each do |vehicle|
          do_force_force = false
          entity_type = :object
          entity_type = :vehicle if ENTITY::IS_ENTITY_A_VEHICLE(vehicle)
          entity_type = :ped if ENTITY::IS_ENTITY_A_PED(vehicle)
          entity_type = nil if vehicle == player_vehicle.to_i
          entity_type = nil if vehicle == player_ped_id.to_i
          entity_type = nil if entity_type == :object && !ENTITY::DOES_ENTITY_HAVE_PHYSICS(vehicle)

          if entity_type == :vehicle
            if explosions_this_tick
              ENTITY::SET_ENTITY_PROOFS(vehicle,false,true,true,false,false,false,false,false)
              proofs_reset = false
            elsif !proofs_reset
              ENTITY::SET_ENTITY_PROOFS(vehicle,false,false,false,false,false,false,false,false)
              proofs_reset = true
            end
          end

          hash = ENTITY::GET_ENTITY_MODEL(vehicle)
          # if HASH_BLACKLIST.key?(hash)
          #   entity_type = nil if HASH_BLACKLIST[hash]
          # elsif hash
          #   if OBJECT::_0x5EAAD83F8CFB4575(hash).to_i != 0
          #     HASH_BLACKLIST[hash] = true
          #   else
          #     HASH_BLACKLIST[hash] = false
          #   end
          # end

          if entity_type
            target_coords = player_coords_orig_vehicle || player_coords

            vehicle_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle,0.0,0.0,0.0)
            distance = GAMEPLAY::GET_DISTANCE_BETWEEN_COORDS(*target_coords,*vehicle_coords,true)
            
            dz = 0.0
            ddd = 1.0
            speed = ENTITY::GET_ENTITY_SPEED(vehicle)
            if EXCITING_OBJECTS_HASH[hash.to_i] && speed > 1.0 && distance < 50.0
              # log "exciting object #{hash} #{vehicle}"
              $excitement = true
              do_force_force = true
              # dd *= 1.0
              ddd = 10.0
              dz = 1.0 / ddd
              target_coords = player_coords_orig_vehicle_o || player_coords

              vehicle_coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle,0.0,0.0,0.0)
              distance = GAMEPLAY::GET_DISTANCE_BETWEEN_COORDS(*target_coords,*vehicle_coords,true)
              distance /= 2.0
              GRAPHICS::DRAW_LINE(*target_coords,*vehicle_coords,255,127,127,255)
            end

            # if xy = GRAPHICS::_WORLD3D_TO_SCREEN2D(*vehicle_coords)
            #   # GUI::Text.new().draw("#{sprintf("%.3f",dd)}",*xy)
            #   GUI::Text.new().draw("#{hash.to_i}",*xy)
            # end

            # if distance < 10.0# && distance > 0.5
            if distance < @radius
              dx = target_coords.x - vehicle_coords.x
              dy = target_coords.y - vehicle_coords.y
              mag = Math.sqrt( dx*dx + dy*dy)
              dx /= mag
              dy /= mag
              dd = ((1.0 + ((@radius - distance) / @radius)) ** @exponent) / @divisor
              dd *= frame_time
              dx *= -1
              dy *= -1
              dd *= ddd


              if do_force || do_force_force
                r,g,b = 255,0,0
                if entity_type == :object

                  # if ENTITY::IS_ENTITY_STATIC(vehicle) && !OBJECT::HAS_OBJECT_BEEN_BROKEN(vehicle) && ENTITY::GET_ENTITY_SPEED(vehicle) == 0.0 # && !MOVED_ENTITIES.include?(vehicle.to_i)
                  if !ENTITY::IS_ENTITY_IN_AIR(vehicle) && !ENTITY::IS_ENTITY_ATTACHED(vehicle) && speed == 0.0 && !MOVED_ENTITIES.include?(vehicle.to_i)
                    # GRAPHICS::DRAW_LINE(*target_coords,*vehicle_coords,0,255,255,255)
                    OBJECT::SET_ACTIVATE_OBJECT_PHYSICS_AS_SOON_AS_IT_IS_UNFROZEN(vehicle,true)
                    explosions << vehicle_coords
                    # if OBJECT::HAS_OBJECT_BEEN_BROKEN(vehicle)
                    #   MOVED_ENTITIES.push(vehicle.to_i)
                    # else
                    #   # big_explosions << vehicle_coords
                    #   MOVED_ENTITIES.push(vehicle.to_i)
                    # end
                  end
                elsif entity_type == :ped

                end
                PED::SET_PED_TO_RAGDOLL(vehicle,1000,1000,0,false,false,false) if entity_type == :ped
                # ENTITY::APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(vehicle,1,dx*dd,dy*dd,0.0,true,false,true,true)
                # ENTITY::APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(vehicle,1,dx*dd,dy*dd,0.0,true,false,true,true)
                ENTITY::APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(vehicle,1,dx*dd,dy*dd,dz*dd,true,false,true,true)
                # GRAPHICS::DRAW_LINE(*target_coords,*vehicle_coords,0,255,127,255)
              end
              $avm_entities.push(vehicle.to_i)
            elsif distance > (@radius * 2)
              $avm_entities.delete(vehicle.to_i) if !$excitement
            end

          end
        end

        if explosions_this_tick
          explosions.each do |v|
            FIRE::ADD_EXPLOSION(v.x+0.0,v.y-0.0,v.z-0.0,ExplosionType::ProgramAR,0.1,false,true,0.0)
          end
          big_explosions.each do |v|
            # FIRE::ADD_EXPLOSION(v.x+0.0,v.y-0.0,v.z+1.0,ExplosionType::Grenade,1.1,false,true,0.0)
            FIRE::ADD_EXPLOSION(v.x+0.0,v.y-0.0,v.z-0.0,ExplosionType::Grenade,0.1,false,true,0.0)
            FIRE::ADD_EXPLOSION(v.x+0.1,v.y-0.1,v.z+1.0,ExplosionType::Bullet,0.1,false,true,0.0)
          end
          explosions = []
          big_explosions = []
        end

        # GUI::Text.new().draw("Pool: #{explosions.size}",0.1,0.1)

      end

      # GAMEPLAY::SET_TIME_SCALE( $excitement ? 0.09 : 1.0 )
      # GAMEPLAY::SET_TIME_SCALE(  0.2 )
      GAMEPLAY::SET_TIME_SCALE(  1.0 )

    end

    GTAV.wait(0)
  end
end

GTAV.register(:AVMUpdater,true) do
  ticks = 9999
  cp = nil
  loop do
    GTAV.wait(0)
    player_ped_id = PLAYER::PLAYER_PED_ID()
    player_vehicle = PED::GET_VEHICLE_PED_IS_USING(player_ped_id)
    if GTAV[:AVM].enabled
      cp = ENTITY::GET_ENTITY_COORDS(player_ped_id,false)
      cp2 = nil
      ents = GTAV::world_get_all_objects()#.last(128)
      ents.concat GTAV::world_get_all_vehicles()
      ents.concat GTAV::world_get_all_peds()
      ents.each do |ent|
        ticks += 1
        if ticks > 50
          ticks = 0
          GTAV.wait(0)
          player_ped_id = PLAYER::PLAYER_PED_ID()
          player_vehicle = PED::GET_VEHICLE_PED_IS_USING(player_ped_id)
          cp = ENTITY::GET_ENTITY_COORDS(player_ped_id,false)
          cp2 = nil
        end

        ce = ENTITY::GET_ENTITY_COORDS(ent,false)
        distance = SYSTEM::VDIST(*cp,*ce)

        if $bullet_script && ENTITY::IS_ENTITY_A_PED(ent)
          if ENTITY::HAS_ENTITY_BEEN_DAMAGED_BY_ENTITY(player_ped_id,ent,true) && ent != player_ped_id.to_i
            cp2 ||= ENTITY::GET_ENTITY_COORDS(player_ped_id,false)
            cp2.z += 1.0
            log "hurt by #{ent}"
            GRAPHICS::DRAW_LINE(*cp2,*ce,255,54,54,200)
            ENTITY::CLEAR_ENTITY_LAST_DAMAGE_ENTITY(player_ped_id)
            ENTITY::SET_ENTITY_HEALTH(player_ped_id,200)
            if !player_vehicle 
              hash = GAMEPLAY::GET_HASH_KEY("weapon_advancedrifle")
              GAMEPLAY::_0xE3A7742E0B7A2F8B(*cp2,*ce,250,true,hash,-1,true,false,1000.0,PLAYER::PLAYER_PED_ID())
            end
          end
        end

        if ENTITY::IS_ENTITY_AN_OBJECT(ent)
          $avm_entities.push(ent.to_i) if distance < 25.0# || EXCITING_OBJECTS_HASH[mod.to_i]
        else
          $avm_entities.push(ent.to_i) if distance < 100.0
        end
      end
    end
  end
end

GTAV.register(:AVMUpdater2,true) do
  last_seen = 0
  evald_objs = QueueSet.new(256)
  loop do
    GTAV.wait(0)
    if $excitement_script && GTAV[:AVM].enabled
      $excitement_object = false
      all = GTAV::world_get_all_objects()
      ind =  0
      all.each{|ent|
        next if $avm_entities.include?(ent)
        # next if evald_objs.include?(ent)
        mod = ENTITY::GET_ENTITY_MODEL(ent)
        if EXCITING_OBJECTS_HASH[mod.to_i]
          $avm_entities.push(ent)
          # PRIORITY_ENTITIES.push(ent)
          $excitement_object = true
        end
        # evald_objs.push(ent)
        last_seen = ent
      }
    end
  end
end