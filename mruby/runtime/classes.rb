
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
end


class UiStyledText < Struct.new(:font, :scale1, :scale2, :r, :g, :b, :a, :alignment, :wrap_x, :wrap_y, :proportional, :str, :x, :y)
  def initialize(options = {})
    self.font         = options[:font]         || 0
    self.scale1       = options[:scale1]       || 0.0
    self.scale2       = options[:scale2]       || 0.5
    self.r            = options[:r]            || 255
    self.g            = options[:g]            || 255
    self.b            = options[:b]            || 255
    self.a            = options[:a]            || 255
    self.alignment    = options[:alignment]    || 1
    self.wrap_x       = options[:wrap_x]       || 0.0
    self.wrap_y       = options[:wrap_y]       || 1.0
    self.proportional = options[:proportional] || true
    self.str          = options[:str]
    self.x            = options[:x]
    self.y            = options[:y]
  end
  def draw(astr = nil, ax = nil, ay = nil, awrap_x = nil, awrap_y = nil)
    self.str = astr if astr
    self.x = ax if ax
    self.y = ay if ay
    self.wrap_x = awrap_x if awrap_x
    self.wrap_y = awrap_y if awrap_y
    raise ArgumentError if !x || !y || !str
    GTAV._draw_text_many(*self)
  end
end

$__data = [
["2","UiTable","====================="],
["UiTable","==================",":)"],
["==================","==================","screen ratio adjusted"]
]
class UiTable < Struct.new(:x, :y, :w, :h, :widths, :data, :p, :pco, :pci, :pro, :pri)
  def initialize(options = {})
    self.x      = options[:x]      || 0.3
    self.y      = options[:y]      || 0.3
    self.w      = options[:w]      || 0.3
    self.h      = options[:h]      || 0.3
    self.widths = options[:widths] || [ 0.25, 0.25, 0.5 ]
    self.data   = options[:data]   || $__data
    self.p      = options[:p]      || 0.01
    self.pco    = options[:pco]      || 0.01
    self.pci    = options[:pci]      || 0.01
    self.pro    = options[:pro]      || 0.01
    self.pri    = options[:pri]      || 0.01
  end
  def draw
    GRAPHICS::DRAW_RECT(x + (w / 2), y + (h / 2), w, h, 255,255,255,127)

    sx = 1080.0 / 1920.0
    dx = x + (p * sx)
    dy = y + p
    rows = data.size
    cols = data[0].size
    rh = ((h - (p * 2) - (rows * pro) + pro) / rows)
    # rh = ((h - (p)) / rows)
    data.each_with_index do |row,ri|
      row.each_with_index do |column,ci|
        cw = (widths[ci] * (w - (p * 2 * sx) - ((pco * sx) * cols) + (pco * sx) ))
        xl = dx + (sx * pci)
        xr = dx + cw - (sx * pci)
        GRAPHICS::DRAW_RECT(dx + (cw / 2), dy + (rh / 2), cw, rh, 0,0,0,127)
        METRICS_TEXT_STYLE.draw(data[ri][ci] || "",xl,dy + pri,xl,xr)
        dx += cw + (pco * sx)
      end
      dy += rh + pro
      dx = x + (p * sx)
    end
  end
  def apply_padding_scale!
    scale = 1920.0 / 1080.0

  end
end
