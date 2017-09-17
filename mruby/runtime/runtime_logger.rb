
module GTAV

  @@logger_buffer = Queue.new(10)
  def self.log(msg,*tags)

    str = ""
    if tags.size > 0
      str << tags.join(" ")
      str << ": "
    end
    
    str << "#{msg}\n"

    @@logger_buffer.push(str)
    print(str)
  end

  def self.logger_buffer
    @@logger_buffer
  end

end

def log(*args)
  GTAV.log(*args)
end