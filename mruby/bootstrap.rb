
module GTAV

  # wrapper classes for native game types
  class BoxedObject < Array
    def initialize(*args)
      __load(*args)
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
    log "#{exception.inspect}", :error
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

  def self.on_shutdown
    log "GTAV.on_shutdown"

    # close all open sockets, so that we can re-bind and re-listen after reloading
    Socket.close_all!
  end

  def self.asi_version
    "0.0.1"
  end

  def self.rb_version
    "0.0.1"
  end

end

def log(*args)
  GTAV.log(*args)
end

def Player(*args)
  GTAV::Player.new(*args)
end

def Ped(*args)
  GTAV::Ped.new(*args)
end

def Vehicle(*args)
  GTAV::Vehicle.new(*args)
end

def Entity(*args)
  GTAV::Entity.new(*args)
end

def Hash(*args)
  if args.size == 1 && args[0].is_a?(Fixnum)
    GTAV::Hash.new(*args)
  else
    super
  end
end

# exceptions created by c code
class CallLimitExceeded < StandardError; end
