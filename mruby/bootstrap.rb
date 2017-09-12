
class Vector3 < Array
  def initialize(*args)
    __load(args)
  end
  def __load(array)
    self.replace(array)
  end
end

class ScriptBase
  def initialize(*); end;
  def tick; end
end

module GTAV

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
    puts "!!! #{exception.message}"
  end

  def self.tick_callbacks
    @@callbacks.each_pair do |name,callback|
      begin
        callback.call
      rescue => ex
        puts "ERROR #{name} - #{ex.message}"
      end
    end
  end

  def self.on_error(exception)
    puts "on_error #{exception.message}"
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
