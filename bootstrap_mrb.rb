
module GTAV

  # initialise once
  puts "I am initing"

  def self.tick(*args)
    puts "Hello I am ticking with args from C: #{args.inspect}"
    retval = self.callnative(0xFFFFFFFF,0xFFFFFFFF, 123, 42069, 219)
    puts "Got #{retval}"
  rescue => exception
    puts "!!! #{exception.message}"
  end

end
