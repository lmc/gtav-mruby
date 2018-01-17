class Queue
  def initialize(max_size)
    @max_size = max_size
    @array = []
  end
  def push(val)
    ret = nil
    ret = @array.shift if @array.size >= @max_size
    @array.push(val)
    ret
  end
  alias << push
  def to_a
    @array.to_a
  end
  def array
    @array
  end
end

class QueueSet < Queue
  def initialize(max_size)
    super
    @hash = {}
    @repush_at = max_size / 3
  end
  def push(val)
    return nil if @hash[val]
    @hash[val] = true
    ret = super(val)
    if ret
      @hash.delete(ret)
    end
    ret
  end
  def include?(val)
    @hash[val]
  end
  def delete(val)
    @hash.delete(val)
  end
  def keys
    @hash.keys
  end
end
