
class Socket

  @@inited = false
  @@sockets = []

  def initialize(fd)
    if !@@inited
      GTAV.socket_init
      @@inited = true
    end
    @@sockets << self
    @fd = fd
    @connected = true
    @errors = {}
  end

  def read(bytes = 128)
    rv = GTAV.socket_read(@fd)
    if rv.is_a?(Fixnum)
      if rv == 0 # 0 bytes read = client disconnected normally
        self.close
        return nil
      else
        @errors[:read] = rv
      end
    else
      return rv
    end
  end

  def write(value)
    rv = GTAV.socket_write(@fd,value)
    if rv.is_a?(Fixnum)
      @errors[:write] = rv
      return nil
    else
      return rv
    end
  end

  def close
    @connected = false
    GTAV.socket_close(@fd)
  end

  def error(type)
    @errors[type]
  end

  def self.listen(port)
    fd = GTAV.socket_listen(port)
    SocketListen.new(fd)
  end

  def self.close_all!
    @@sockets.each(&:close)
  end
end

class SocketListen < Socket
  def accept!
    fd = GTAV.socket_accept(@fd)
    if fd == 0 || fd.nil? # 0 == INVALID_SOCKET
      return nil
    elsif fd < 0
      return nil
    else
      return Socket.new(fd)
    end
  end
end
