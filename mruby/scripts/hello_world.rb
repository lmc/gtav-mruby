GTAV.load("./mruby/load_test.rb")

class HelloWorld
	def initialize
		puts "HelloWorld#initialize"
	end
	def call
		puts "HelloWorld#call"

		player_id, player_ped_id = GTAV::PLAYER::PLAYER_ID(), GTAV::PLAYER::PLAYER_PED_ID()
		puts "player_id: #{player_id}, player_ped_id: #{player_ped_id}"

		coords = GTAV::ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(GTAV::PLAYER::PLAYER_PED_ID(),0.0,0.0,0.0)
		puts "entity: #{coords.class} #{coords.inspect}"

		# vector3 = Vector3.new(123.511,420.168,69.913)
		# puts "vector3: #{vector3.inspect}"
	end
end

GTAV.register(:HelloWorld,HelloWorld.new)
