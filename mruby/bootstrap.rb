
module GTAV

  # wrapper classes for native game types
  class BoxedObject < Array
    def initialize(*args)
      __load(args)
    end

    def __load(*value)
      self.replace(value)
    end
  end

  class Vector3 < BoxedObject; end

  class BoxedObjectInt < BoxedObject; end

  class Any < BoxedObjectInt; end

  class Entity < BoxedObjectInt; end

  class Ped < Entity; end
  class Vehicle < Entity; end
  class Object < Entity; end

  class Player < BoxedObjectInt; end
  class Pickup < BoxedObjectInt; end
  class Blip < BoxedObjectInt; end

  class Hash < BoxedObjectInt; end
  class ScrHandle < BoxedObjectInt; end
  class Cam < BoxedObjectInt; end

  # gets called every engine tick by script.cpp
  def self.tick(*args)
    log "Bootstrapped GTAV.tick, ensure a runtime is loaded"
  end

  def self.on_error(exception)
    log "#{exception.class} - #{exception.message}", :error
    exception.backtrace.each do |bt|
      log "  #{bt}", :error
    end
  end

  def self.load_script(filename)
    begin
      GTAV.load(filename)
    rescue => ex
      on_error(ex)
    end
  end

  def self.wait(ms)
    log "Bootstrapped GTAV.wait, ensure a runtime is loaded"
  end

  def self.register(*,&block)
    log "Bootstrapped GTAV.register, ensure a runtime is loaded"
    block.call if block_given?
  end

  def self.log(*args)
    puts "GTAV.log - #{args.inspect}"
  end

  # create empty file called `enable-socket` in this dir, then override this method
  # the socket is read immediately on accept, and provided as a string in the `input` arg
  # return a string to have it written to the socket before it's closed
  def self.on_socket(input)
    return "GTAV.on_socket()"
  end

end

def log(*args)
  GTAV.log(*args)
end

# exceptions created by c code
class CallLimitExceeded < StandardError; end
