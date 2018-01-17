
module GTAV

  @@logger_buffer = Queue.new(32)
  @@logger_meta_buffer = Queue.new(32)
  def self.log(msg,*tags)
    time = GTAV.time_usec

    str = ("%.6f " % time).rjust(15," ")
    if tags.size > 0
      str << tags.join(" ")
      str << ": "
    end
    
    str << "#{msg}\n"

    @@logger_buffer.push(msg)
    @@logger_meta_buffer.push([tags,time])
    print(str)
  end

  def self.logger_buffer
    @@logger_buffer
  end

  def self.logger_meta_buffer
    @@logger_meta_buffer
  end

end
