
module GTAV

  class BoxedObject < ::Array
    def initialize(*args)
      __load(args)
    end
    def inspect
      "#{self.class.to_s.gsub("GTAV::","")}(#{self.map{|i| i.inspect}.join(", ")})"
    end
  end

  class Vector3 < BoxedObject
    def __load(*value)
      self.replace(value)
    end
    def x; self[0]; end
    def y; self[1]; end
    def z; self[2]; end
    def x=(v); self[0] = v; end
    def y=(v); self[1] = v; end
    def z=(v); self[2] = v; end
  end

  class BoxedObjectInt < BoxedObject
    def __load(value)
      self.replace([value])
    end
    def to_i; self[0]; end
  end

  class Entity < BoxedObjectInt; end
  class Player < BoxedObjectInt; end
  class Ped < BoxedObjectInt; end
  class Vehicle < BoxedObjectInt; end
  class Object < BoxedObjectInt; end
  class Pickup < BoxedObjectInt; end

  class Hash < BoxedObjectInt; end
  class ScrHandle < BoxedObjectInt; end
  class Cam < BoxedObjectInt; end

  class Script
    def initialize(*); end;
    def tick; end
  end

  @@state = nil
  @@filenames = {}
  @@callbacks = {}

  def self.register(name,instance)
    puts "register #{name}"
    @@callbacks[name] = instance
  end

  # gets called every engine tick by script.cpp
  def self.tick(*args)
    self.reload! if GTAV.is_key_just_up(0x7A) # F11
    self.tick_callbacks()
  rescue => exception
    self.on_error(exception)
  end

  def self.tick_callbacks
    @@callbacks.each_pair do |name,callback|
      begin
        callback.call
      rescue => ex
        puts "ERROR IN #{name}"
        on_error(ex)
        puts
      end
    end
  end

  def self.on_error(exception)
    puts "#{exception.message}"
    exception.backtrace.each do |bt|
      puts bt
    end
  end

  def self.load_script(filename)
    puts "GTAV.load_script(#{filename.inspect})"
    @@filenames[filename] = true
    GTAV.load(filename)
  end

  def self.reload!
    puts "GTAV.reload!"
    @@state = :reloading
    @@filenames.each_pair do |filename,_|
      GTAV.load_script(filename)
    end
  ensure
    @@state = nil
    puts "GTAV.reload! complete"
  end

  def self.reloading?
    @@state == :reloading
  end
end
