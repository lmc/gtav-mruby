
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
    log "#{exception.class} - #{exception.message}", :error, :message
    exception.backtrace.each do |bt|
      log "  #{bt}", :error, :backtrace
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
  
  @@on_shutdown_calls = []
  def self.on_shutdown(&block)
    if block_given?
      @@on_shutdown_calls << block
      return
    end
    log "GTAV.on_shutdown"
    @@on_shutdown_calls.each do |call|
      begin
        call.call
      rescue => ex
        on_error(ex)
      end
    end
    # close all open sockets, so that we can re-bind and re-listen after reloading
    Socket.close_all!
  end

  def self.asi_version
    "0.0.3"
  end

  def self.rb_version
    "0.0.3"
  end

  def self.natives_modules
    [
      PLAYER,
      ENTITY,
      PED,
      VEHICLE,
      OBJECT,
      AI,
      GAMEPLAY,
      AUDIO,
      CUTSCENE,
      INTERIOR,
      CAM,
      WEAPON,
      ITEMSET,
      STREAMING,
      SCRIPT,
      UI,
      GRAPHICS,
      STATS,
      BRAIN,
      MOBILE,
      APP,
      TIME,
      PATHFIND,
      CONTROLS,
      DATAFILE,
      FIRE,
      DECISIONEVENT,
      ZONE,
      ROPE,
      WATER,
      WORLDPROBE,
      NETWORK,
      NETWORKCASH,
      DLC1,
      DLC2,
      SYSTEM,
      DECORATOR,
      SOCIALCLUB,
      UNK,
      UNK1,
      UNK2,
      UNK3,
    ]
  end

end

def log(*args)
  GTAV.log(*args)
end

# exceptions created by c code
class CallLimitExceeded < StandardError; end
