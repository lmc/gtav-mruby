# # GTAV.load("./mruby/load_test.rb")

# class HelloWorld < GTAV::Script
#   def initialize
#     puts "HelloWorld#initialize"
#   end
#   def call
    # # if GTAV.is_key_just_up(0x79) # VK_F10
    # if true
    #   player_id, player_ped_id = PLAYER::PLAYER_ID(), PLAYER::PLAYER_PED_ID()
    #   # puts "player_id: #{player_id.inspect}, player_ped_id: #{player_ped_id.inspect}"
    #   coords1 = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_ped_id,-3.0,5.0,1.0)
    #   coords2 = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_ped_id,3.0,5.0,3.0)
    #   # puts "#{coords1.inspect},#{coords2.inspect}"
    #   # GRAPHICS::SET_DEBUG_LINES_AND_SPHERES_DRAWING_ACTIVE(true)
    #   GRAPHICS::DRAW_LINE(*coords1,*coords2,0,255,0,255)

    #   # puts PED::STOP_ANY_PED_MODEL_BEING_SUPPRESSED().inspect
    #   # puts "last vehicle #{PLAYER::GET_PLAYERS_LAST_VEHICLE().inspect}"
    #   # puts "this vehicle #{PED::GET_VEHICLE_PED_IS_USING(player_ped_id).inspect}"
    #   # puts "health: #{PED::GET_PED_MAX_HEALTH(player_ped_id).inspect}"

    #   # puts PED::SET_PED_GET_OUT_UPSIDE_DOWN_VEHICLE(player_ped_id,2).inspect
    # # File.open("write_test","w"){|f| f << "hello"}

    # else
    #   # GRAPHICS::SET_DEBUG_LINES_AND_SPHERES_DRAWING_ACTIVE(false)
    # end

#     # if GTAV.is_key_just_up(0x78) #F9
#     puts "checking"
#     if GTAV.is_key_just_up(0x76) # F7
#       puts "spawning"
#       model = "BULLET"
#       hash = GAMEPLAY::GET_HASH_KEY(model)
#       if STREAMING::IS_MODEL_IN_CDIMAGE(hash) && STREAMING::IS_MODEL_A_VEHICLE(hash)
#         STREAMING::REQUEST_MODEL(hash)
#         GTAV.wait(0) until STREAMING::HAS_MODEL_LOADED(hash)
#         coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER::PLAYER_PED_ID(),0.0,5.0,1.0)
#         vehicle = VEHICLE::CREATE_VEHICLE(hash,*coords,0.0,true,true)
#         puts "vehicle: #{vehicle.inspect}"
#         GTAV.wait(1000)
#         STREAMING::SET_MODEL_AS_NO_LONGER_NEEDED(hash)
#         # ENTITY::SET_VEHICLE_AS_NO_LONGER_NEEDED(vehicle)
#         VEHICLE::DELETE_VEHICLE(vehicle)
#       end
#     end
    
#   end
# end


# good tracks = 1/1495 - midnight city
# good tracks = 1/1497 - applause
# good tracks = 14/1348 - sleep walking
# good tracks = 14/1278 - from nowhere

vehicle = nil
in_demo = false
@demo_start = 0
faded_in = false
right_music = false
DEMO_COORDS = GTAV::Vector3.new( 0.0, 3000.0, 300.0 )

bc = 0.0

def demo_time
  GTAV.time_usec - @demo_start
end

def find_right_music
  log "find_right_music "
  loop do
    ppid = PLAYER::PLAYER_PED_ID()
    vehicle = PED::GET_VEHICLE_PED_IS_USING(ppid)
    COORDS_TEXT.draw("#{AUDIO::GET_PLAYER_RADIO_STATION_INDEX()}",0.3,0.3)
    COORDS_TEXT.draw("#{AUDIO::GET_AUDIBLE_MUSIC_TRACK_TEXT_ID()}",0.3,0.4)
    track_id = AUDIO::GET_AUDIBLE_MUSIC_TRACK_TEXT_ID().to_i
    if track_id == 1
      AUDIO::SKIP_RADIO_FORWARD()
      GTAV.wait(100)
    # elsif AUDIO::GET_PLAYER_RADIO_STATION_INDEX() == 14 && [1278,1348].include?(track_id)
    elsif AUDIO::GET_PLAYER_RADIO_STATION_INDEX() == 14 && [1278].include?(track_id)
      right_music  = true
      # AUDIO::SET_VEHICLE_RADIO_ENABLED(vehicle,true)
      # AUDIO::SET_MOBILE_RADIO_ENABLED_DURING_GAMEPLAY(false)
      log "got track #{track_id}"
      return
    else
      AUDIO::SKIP_RADIO_FORWARD()
      GTAV.wait(100)
    end
  end
end

def draw_tracks(ox,oy,oz)
  ppid = PLAYER::PLAYER_PED_ID()
  vehicle = PED::GET_VEHICLE_PED_IS_USING(ppid)
  
  fl = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle,  1.2 + ox,  3.6 + oy, -0.5 + oz)
  fr = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, -1.2 + ox,  3.6 + oy, -0.5 + oz)
  bl = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle,  1.2 + ox, -3.6 + oy, -0.5 + oz)
  br = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, -1.2 + ox, -3.6 + oy, -0.5 + oz)

  GRAPHICS::DRAW_POLY(*fl,*fr,*bl,127,0,127,127)
  GRAPHICS::DRAW_POLY(*bl,*fr,*br,127,0,127,127)

  GRAPHICS::DRAW_LINE(*fl,*bl,0,255,255,200)
  GRAPHICS::DRAW_LINE(*fr,*br,0,255,255,200)
  GRAPHICS::DRAW_LINE(*fl,*fr,0,255,255,200)
  GRAPHICS::DRAW_LINE(*bl,*br,0,255,255,200)
end

def draw_blocker(a = 255)
  # log "a: #{a}"
  ppid = PLAYER::PLAYER_PED_ID()
  vehicle = PED::GET_VEHICLE_PED_IS_USING(ppid)
  
  fl = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle,  10.0, -4.0, -10.0)
  fr = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, -10.0, -4.0, -10.0)
  bl = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle,  10.0, -4.0,  10.0)
  br = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, -10.0, -4.0,  10.0)

  GRAPHICS::DRAW_POLY(*bl,*fr,*fl,0,0,0,a)
  GRAPHICS::DRAW_POLY(*br,*fr,*bl,0,0,0,a)

end

def scale(input,r0,r1,o0,o1)
  frac = (input - r0) / (r1 - r0)
  o0 + (frac * (o1 - o0))
end

def intro_text(str,x,y, start_fade_in, stop_fade_in, start_fade_out, stop_fade_out)
  if demo_time > start_fade_in && demo_time < stop_fade_out
    INTRO_TEXT.a = 0
    if demo_time > start_fade_in && demo_time < stop_fade_in
      INTRO_TEXT.a = scale(demo_time,start_fade_in,stop_fade_in,0,255)
    elsif demo_time > stop_fade_in && demo_time < start_fade_out
      INTRO_TEXT.a = 255
    elsif demo_time > start_fade_out && demo_time < stop_fade_out
      INTRO_TEXT.a = 255 - scale(demo_time,start_fade_out,stop_fade_out,0,255)
    end
    INTRO_TEXT.draw(str,x,y)
  end
end

text3d_y = 0.0
faded_out = false
faded_out2 = false
faded_in = false
sped_up = false
spx0 = 0.1
spx1 = 0.05
COORDS_TEXT = UiStyledText.new()
INTRO_TEXT = UiStyledText.new(font: 7, alignment: 0, a: 0, scale2: 2.0)


GTAV.register(:HelloWorld,false) do
  loop do

    pid = PLAYER::PLAYER_ID()
    ppid = PLAYER::PLAYER_PED_ID()
    vehicle = PED::GET_VEHICLE_PED_IS_USING(ppid)

    if GTAV.is_key_just_up(0x76) # F7

      if in_demo
        AUDIO::SKIP_RADIO_FORWARD()
      else

        AUDIO::SET_MOBILE_RADIO_ENABLED_DURING_GAMEPLAY(true)
        AUDIO::SET_RADIO_TO_STATION_INDEX(14)
        GTAV.wait(10)
        find_right_music
        AUDIO::SET_MOBILE_RADIO_ENABLED_DURING_GAMEPLAY(false)

        # CAM::DO_SCREEN_FADE_OUT(0)
        # AUDIO::SET_MOBILE_RADIO_ENABLED_DURING_GAMEPLAY(true)
        model = "BULLET"
        hash = GAMEPLAY::GET_HASH_KEY(model)
        if STREAMING::IS_MODEL_IN_CDIMAGE(hash) && STREAMING::IS_MODEL_A_VEHICLE(hash)
          STREAMING::REQUEST_MODEL(hash)
          GTAV.wait(0) until STREAMING::HAS_MODEL_LOADED(hash)
          coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER::PLAYER_PED_ID(),0.0,5.0,1.0)
          vehicle = VEHICLE::CREATE_VEHICLE(hash,*coords,0.0,true,true)
          puts "vehicle: #{vehicle.inspect}"
          # GTAV.wait(1000)
          STREAMING::SET_MODEL_AS_NO_LONGER_NEEDED(hash)
          VEHICLE::SET_VEHICLE_COLOURS(vehicle,VehicleColor::MetallicFrostWhite,VehicleColor::MetallicVermillionPink)
          VEHICLE::SET_VEHICLE_GRAVITY(vehicle,false)
          ENTITY::SET_ENTITY_COORDS(vehicle, 100.0, -1100.0, 300.0 ,false,false,false,false)
          ENTITY::SET_ENTITY_ROTATION(vehicle, 0.0, 0.0, 0.0, 0, false)
          ENTITY::SET_VEHICLE_AS_NO_LONGER_NEEDED(vehicle)
        end
        set_ped_into_vehicle(ppid,vehicle,-1)
        AUDIO::SET_RADIO_TO_STATION_INDEX(14)
        AUDIO::SET_VEHICLE_RADIO_ENABLED(vehicle,false)
        # AUDIO::SET_MOBILE_RADIO_ENABLED_DURING_GAMEPLAY(true)
        # AUDIO::PLAY_END_CREDITS_MUSIC(true)
        in_demo = true
        @demo_start = GTAV.time_usec

        GAMEPLAY::SET_WEATHER_TYPE_NOW_PERSIST("EXTRASUNNY")
        TIME::SET_CLOCK_TIME(23,0,0)
        # GTAV.wait(3000)
        # CAM::DO_SCREEN_FADE_IN(5000)
      end
    end

    if in_demo
      cam = CAM::GET_RENDERING_CAM()

      cp = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle,  3.0,  -3.6, -1.5)
      ct = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle,  3.0,  -0.6, -1.5)

      CAM::SET_CAM_COORD(cam,*cp)
      CAM::POINT_CAM_AT_COORD(cam,*ct)

      UI::HIDE_HUD_AND_RADAR_THIS_FRAME()
      if bc < -7.2
        bc = 0.0
      else
        bc -= spx0
      end
      # log "bc: #{bc}"
      # find_right_music if !right_music
      13.times do |i|
        draw_tracks(0.0, bc + (7.2 * i.to_f), 0.0)
      end

      if demo_time > 0 && demo_time < 10.0
        # draw_blocker(255 - scale(demo_time,5,12,0,255))
        draw_blocker(255)
        intro_text("opius presents",0.5,0.3,  1.0,3.0,6.0,9.0)
      elsif demo_time > 10.0 && demo_time < 19.0
        intro_text("project",0.5,0.3,  7.0,7.5,15.0,19.0)
      end

      if demo_time > 6.0 && !faded_out
        CAM::DO_SCREEN_FADE_OUT(3000)
        faded_out = true
      elsif demo_time > 10.0 && !faded_in
        AUDIO::SET_VEHICLE_RADIO_ENABLED(vehicle,true)
        CAM::DO_SCREEN_FADE_IN(10000)
        faded_in = true
      elsif demo_time > 52.0 && !sped_up # actual track time is ~65.5
        spx0 = 0.3
        spx1 = 0.15
        sped_up = true
      elsif demo_time > 93.0 && !faded_out2
        CAM::DO_SCREEN_FADE_OUT(10000)
        faded_out2 = true
      end

      ENTITY::APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(vehicle,1,0.0,spx1,0.0,false,false,true,true)
      # draw_3d_char(vehicle,"B",  -2.0, 4.0, 2.0,  0.8, 1.0)
      # draw_3d_char(vehicle,"O",  -1.0, 4.0, 2.0,  0.8, 1.0)
      # draw_3d_char(vehicle,"O",   0.0, 4.0, 2.0,  0.8, 1.0)
      # draw_3d_char(vehicle,"B",   1.0, 4.0, 2.0,  0.8, 1.0)

      # 0.0 - 1.0 = black-blocked
      # 1.0 - 3.0 = text fade in
      # 3.0 - 6.0 = text sustain, engine start sound
      # 6.0 - 9.0 = text fade
      # 9.0 - 15.0 = fade in to game, with sound
    end
    COORDS_TEXT.draw("#{demo_time}",0.05,0.05)
    GTAV.wait(0)
  end
end

# def spawn_vehicle(model)
#   hash = GAMEPLAY::GET_HASH_KEY(model)
#   if STREAMING::IS_MODEL_IN_CDIMAGE(hash) && STREAMING::IS_MODEL_A_VEHICLE(hash)
#     STREAMING::REQUEST_MODEL(hash)
#     # GTAV.wait(0) until STREAMING::HAS_MODEL_LOADED(hash)
#     STREAMING::LOAD_ALL_OBJECTS_NOW()
#     coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER::PLAYER_PED_ID(),0.0,5.0,1.0)
#     vehicle = VEHICLE::CREATE_VEHICLE(hash,*coords,0.0,true,true)
#     # GTAV.wait(0)
#     STREAMING::SET_MODEL_AS_NO_LONGER_NEEDED(hash)
#     ENTITY::SET_VEHICLE_AS_NO_LONGER_NEEDED(vehicle)
#     return true
#   end
# end

PIXEL_FONT = {
  " " => [
    [0,0,0,0,0],
    [0,0,0,0,0],
    [0,0,0,0,0],
    [0,0,0,0,0],
    [0,0,0,0,0],
  ],
  "A" => [
    [0,0,1,0,0],
    [0,1,0,1,0],
    [1,1,1,1,1],
    [1,0,0,0,0],
    [1,0,0,0,1],
  ],
  "B" => [
    [1,1,1,1,0],
    [1,0,0,0,1],
    [1,1,1,1,0],
    [1,0,0,0,1],
    [1,1,1,1,0],
  ],
  "C" => [
    [0,0,1,1,1],
    [0,1,0,0,0],
    [1,0,0,0,0],
    [0,1,0,0,0],
    [0,0,1,1,1],
  ],
  "D" => [
    [1,1,1,0,0],
    [1,0,0,1,0],
    [1,0,0,0,1],
    [1,0,0,1,0],
    [1,1,1,0,0],
  ],

    "O" => [
    [0,1,1,1,0],
    [1,0,0,0,1],
    [1,0,0,0,1],
    [1,0,0,0,1],
    [0,1,1,1,0],
  ],

}


def draw_3d_char(ref, char, dx,dy,dz, w,h)
  ox,oy,oz = *ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ref, dx,dy,dz)
  sx = w.to_f / 5.0
  sy = h.to_f / 5.0
  bitmap = PIXEL_FONT[char]
  bitmap.each_with_index do |row,ri|
    ri = ri.to_f
    row.each_with_index do |col,ci|
      ci = ci.to_f
      if col == 1
        tl = GTAV::Vector3.new( ox + (sx * ci)      , oy , oz + (sy * ri)      )
        tr = GTAV::Vector3.new( ox + (sx * ci) + sx , oy , oz + (sy * ri)      )
        bl = GTAV::Vector3.new( ox + (sx * ci)      , oy , oz + (sy * ri) + sy )
        br = GTAV::Vector3.new( ox + (sx * ci) + sx , oy , oz + (sy * ri) + sy )

        # log("#{[*tl,*tr,*bl].map(&:class)}")
        # log("#{[tl.x,tl.y,tl.z]}")
        # args = 
        GRAPHICS::DRAW_POLY(*tl,*tr,*bl,127,0,127,127)
        GRAPHICS::DRAW_POLY(*bl,*tr,*br,127,0,127,127)
      end
    end
  end
end
