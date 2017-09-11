
class Vector3 < Array
  def initialize(*args)
    __load(args)
  end
  def __load(array)
    self.replace(array)
  end
end

module GTAV

  # initialise once
  puts "I am initing"

  @@callbacks = {}

  def self.register(name,instance)
    puts "register #{name}"
    @@callbacks[name] = instance
  end

  def self.tick(*args)
    # puts "Hello I am ticking with args from C: #{args.inspect}"
    # retval = self.callnative(0xFFFFFFFF,0xFFFFFFFF, 123, 42069, 219)
    # puts "Got #{retval}"
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

end
