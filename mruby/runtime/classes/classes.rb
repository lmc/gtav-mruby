
class GTAV::BoxedObject
  def inspect
    "#{self.class.to_s.gsub("GTAV::","")}(#{self.map{|i| i.inspect}.join(", ")})"
  end
  def to_s
    inspect
  end
end

class GTAV::BoxedObjectInt
  def to_i; self[0]; end
end

class GTAV::Vector3
  def x; self[0]; end
  def y; self[1]; end
  def z; self[2]; end
  def x=(v); self[0] = v; end
  def y=(v); self[1] = v; end
  def z=(v); self[2] = v; end
end

class Class
  def name
    to_s
  end
end

class Module
  def name
    to_s
  end
end

module GTAV
  @@boot_time = Time.now.to_i

  def self.time
    time = Time.now
    sec,usec = time.to_i, time.usec
    sec -= @@boot_time
    (sec.to_i * 1000) + (usec / 1000).to_i
  end

  def self.time_usec
    time = Time.now
    sec,usec = time.to_i, time.usec
    sec -= @@boot_time
    sec.to_f + (usec.to_f / 1000000.0)
  end

end

def enum_to_hash(enum)
  hash = {}
  enum.constants.each do |key|
    hash[ enum.const_get(key) ] = key.to_s
  end
  hash
end

def terminate_script_named(target)
  SCRIPT::_0xDADFADA5A20143A8()
  loop do
    idx = SCRIPT::_0x30B4FA1C82DD4B9F()
    break if idx <= 0
    name = SCRIPT::_GET_THREAD_NAME(idx)
    if name == target
      SCRIPT::TERMINATE_THREAD(idx)
      return true
    end
  end
  false
end

$__every_next = Hash.new{ |h,k| h[k] = 0 }
def every(ms,time = GTAV.time,&block)
  if $__every_next[block.source_location.hash] <= time
    yield
    $__every_next[block.source_location.hash] = time + ms
  end
end

# maybe lambda#debounce instead ?
# or metaprogramming to alias_method_chain it

def search_memory(pattern, start = nil, stop = nil)
  start = GTAV.memory_base if !start
  stop  = start + GTAV.memory_base_size if !stop
  pattern_i = 0
  start.upto(stop) do |addr|
    if pattern_i >= pattern.size
      return addr - pattern.size
    elsif pattern[pattern_i].nil?
      pattern_i += 1
    elsif GTAV.memory_read(addr,1).ord == pattern[pattern_i]
      pattern_i += 1
    else
      pattern_i = 0
    end
  end
  return nil
end

# puts "searching memory - #{GTAV.memory_read(GTAV.memory_base,1).ord}"
# _ = nil

# # this pattern don't work
# # res = search_memory( [0x80,0x3D,_,_,_,_,_,0x74,0x27,0x84,0xC0] )

# # this pattern works
# res = search_memory( [0x44,0x38,0x3d,_,_,_,_,0x74,0x0f] )
# # res = search_memory( ["M".ord,"Z".ord] )
# puts "res: #{res.inspect}"
# puts "res: #{GTAV.memory_read(res,14).bytes.inspect}"
# $original = GTAV.memory_read(res,14)
# GTAV.memory_write(res,([0x90] * 14).map(&:chr).join)
