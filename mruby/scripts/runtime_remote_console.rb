

GTAV.register(:RuntimeRemoteConsole,CONFIG["console.remote.enabled"]) do
  GTAV.wait(0)

  @port = CONFIG["console.remote.port"]
  @server = Socket.listen(@port)
  log "RemoteConsole server listening on port #{@port}", :info

  def evaluate_input(input)
    ret = begin
      cmd,args = input.split(" ",2)
      case cmd
      when "PING"
        "PONG #{GTAV.time}"
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

  loop do

    if @client = @server.accept!
      inp = @client.read
      out = evaluate_input(inp)
      @client.write(out)
      @client.close
    end

    GTAV.wait(0)

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

end
