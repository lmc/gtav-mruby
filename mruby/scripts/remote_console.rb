
GTAV.register(:RemoteConsole,CONFIG["console.remote.enabled"]) do

  @port = CONFIG["console.remote.port"]
  @server = Socket.listen(@port)
  log "RemoteConsole server listening on port #{@port}", :info

  def evaluate_input(input)
    ret = begin
      cmd,args = input.split(" ",2)
      case cmd
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
    return "#{ret}" # be super-duper ensure it's a string
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

end
