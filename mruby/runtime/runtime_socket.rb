
module GTAV
  def self.on_socket(input)
    ret = begin
      # puts "GTAV.on_socket - #{input}"
      cmd,args = input.split(" ",2)
      case cmd
      when "SPAWNVEHICLE"
        spawn_vehicle(args)
      when "GRAVITY"
        GAMEPLAY::SET_GRAVITY_LEVEL(args.to_i)
      when "PLAYERDATA"
        ppid = PLAYER::PLAYER_PED_ID()
        [ppid,ENTITY::GET_ENTITY_COORDS(ppid,false)].inspect
      when "EVAL"
        if GTAV.is_syntax_valid?(args)
          eval(args)
        else
          "ERROR Syntax Error"
        end
      else
        "?"
      end
    rescue => ex
      "ERROR #{ex.to_s}"
    end
    return "#{ret}" #super-duper ensure it's a string
  end
end

def rpc_data()
  entities = ($all_entities || []).to_a
  entities.unshift( PLAYER::PLAYER_PED_ID() )
  # entities = []
  # entities += [ PLAYER::PLAYER_PED_ID() ]
  # entities += GTAV::world_get_all_vehicles()[0..32]
  # entities += GTAV::world_get_all_peds()[0..32]
  entities[0...32].map do |entity|
    [
      entity.to_i,
      ENTITY::GET_ENTITY_COORDS(entity,true).to_a,
      ENTITY::GET_ENTITY_HEADING(entity)
    ].flatten
  end
end
