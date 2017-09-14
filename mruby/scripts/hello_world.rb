# GTAV.load("./mruby/load_test.rb")

class HelloWorld < GTAV::Script
	def initialize
		puts "HelloWorld#initialize"
	end
	def call
		# if GTAV.is_key_just_up(0x79) # VK_F10
		if true
			player_id, player_ped_id = PLAYER::PLAYER_ID(), PLAYER::PLAYER_PED_ID()
			puts "player_id: #{player_id.inspect}, player_ped_id: #{player_ped_id.inspect}"
			coords1 = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_ped_id,-3.0,5.0,1.0)
			coords2 = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_ped_id,3.0,5.0,3.0)
			# puts "#{coords1.inspect},#{coords2.inspect}"
			# GRAPHICS::SET_DEBUG_LINES_AND_SPHERES_DRAWING_ACTIVE(true)
			GRAPHICS::DRAW_LINE(*coords1,*coords2,0,255,0,255)

			# puts PED::STOP_ANY_PED_MODEL_BEING_SUPPRESSED().inspect
			puts "last vehicle #{PLAYER::GET_PLAYERS_LAST_VEHICLE().inspect}"
			puts "this vehicle #{PED::GET_VEHICLE_PED_IS_USING(player_ped_id).inspect}"
			puts "health: #{PED::GET_PED_MAX_HEALTH(player_ped_id).inspect}"
		else
			# GRAPHICS::SET_DEBUG_LINES_AND_SPHERES_DRAWING_ACTIVE(false)
		end
		
	end
end

GTAV.register(:HelloWorld,HelloWorld.new) unless GTAV.reloading?