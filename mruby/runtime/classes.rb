
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

class UiTable < Struct.new(:x, :y, :w, :h, :rh, :widths, :data, :p, :pco, :pci, :pro, :pri, :cell_text, :header_row_text, :body_row_text)
  def initialize(options = {})
    self.x      = options[:x]      || 0.3
    self.y      = options[:y]      || 0.3
    self.w      = options[:w]      || 0.3
    self.h      = options[:h]      || 0.3
    self.rh     = options[:rh]     || nil
    self.widths = options[:widths] || [ 1.0 ]
    self.data   = options[:data]   || [ ["UiTable"] ]
    self.p      = options[:p]      || 0.01
    self.pco    = options[:pco]      || 0.01
    self.pci    = options[:pci]      || 0.01
    self.pro    = options[:pro]      || 0.01
    self.pri    = options[:pri]      || 0.0
    self.cell_text = options[:cell_text] || UiStyledText.new(font: 4, scale2: 1.3)
    self.header_row_text = options[:header_row_text] || nil
    self.body_row_text = options[:body_row_text] || nil
  end
  def draw
    sx = 1080.0 / 1920.0
    dx = x + (p * sx)
    dy = y + p
    rows = data.size || 1
    cols = data[0].size || 1
    if rh
      drh = rh
      self.h = (p * 2) + (rh * rows) + (pro * rows) - pro
    else
      drh = ((h - (p * 2) - (rows * pro) + pro) / rows)
    end
    GRAPHICS::DRAW_RECT(x + (w / 2), y + (h / 2), w, h, 255,255,255,127)
    data.each_with_index do |row,ri|
      row.each_with_index do |column,ci|
        text_class = text_class_for(ri,ci)
        cw = ((widths[ci] || 0.0) * (w - (p * 2 * sx) - ((pco * sx) * cols) + (pco * sx) ))
        xl = dx + (sx * pci)
        xr = dx + cw - (sx * pci)
        GRAPHICS::DRAW_RECT(dx + (cw / 2), dy + (drh / 2), cw, drh, 0,0,0,127)
        text_class.draw(data[ri][ci] || "",xl,dy + pri,xl,xr)
        dx += cw + (pco * sx)
      end
      dy += drh + pro
      dx = x + (p * sx)
    end
  end
  def text_class_for(ri,ci)
    if ri == 0
      header_row_text || cell_text
    else
      body_row_text || cell_text
    end
  end
end


class UiBarChart < Struct.new(:x, :y, :w, :h, :p, :limits, :bw, :data)
  def initialize(options = {})
    self.x         = options[:x] || 0.33
    self.y         = options[:y] || 0.33
    self.w         = options[:w] || 0.33
    self.h         = options[:h] || 0.33
    self.p         = options[:p] || 0.01
    self.limits    = options[:limits] || [0.0,1.0]
    self.bw        = options[:bw] || 0.0033
    self.data      = options[:data] || []
  end
  def draw
    ct = y
    cb = y + h
    dw = (bw * data.size)
    ym = limits[1]
    GRAPHICS::DRAW_RECT(x + (dw / 2.0) - (bw / 2.0),ct + (h / 2.0) + 0.005,dw,h,0,0,0,127)

    data.each_with_index do |d,i|
      val = (d + 0.0) / ym
      if d > ym
        rgba = [255,0,0,127]
      elsif d >= 0.004
        rgba = [255,255,0,127]
      else
        rgba = [0,255,0,127] 
      end
      dh = ct + (val * h)
      dy = cb - (val * (h * 0.5))
      GRAPHICS::DRAW_RECT(x + (bw * i),dy,bw,dh,*rgba)
    end
  end
end

class Menu
  def initialize(options = {})
    options = options.dup
    @table_options = options.delete(:table_options) || {}
    @table_options[:widths] = [1.0]
    @table = UiTable.new(@table_options)
    @selected = 0
    @data = [["menu"]]
    @visible = false
    @on_nav_left_pressed = nil
    @on_nav_right_pressed = nil
  end

  def visible?; @visible; end
  def show; @visible = true; end
  def hide; @visible = false; end

  def data; @data; end
  def data=(v); @data = v; end

  def selected; @selected; end
  def selected=(v)
    @selected = v
    cap_selected!
  end

  def cap_selected!
    @selected = 0 if @selected < 0
    @selected = (data.size - 1) if @selected >= (data.size - 1)
  end

  def on_nav_left_pressed(&block)
    @on_nav_left_pressed = block
  end
  def on_nav_right_pressed(&block)
    @on_nav_right_pressed = block
  end

  def draw
    if @visible
      @on_nav_left_pressed.call  if @on_nav_left_pressed  && nav_left_pressed?
      @on_nav_right_pressed.call if @on_nav_right_pressed && nav_right_pressed?
      @selected -= 1 if nav_up_pressed?
      @selected += 1 if nav_down_pressed?
      cap_selected!
      @table.data = data.map(&:dup)
      @table.data[@selected][0] = "> #{data[@selected][0]}"
      @table.draw
    end
  end

  def nav_up_pressed?
    GTAV.is_key_just_up(0x26)
  end
  def nav_down_pressed?
    GTAV.is_key_just_up(0x28)
  end
  def nav_left_pressed?
    GTAV.is_key_just_up(0x25)
  end
  def nav_right_pressed?
    GTAV.is_key_just_up(0x27)
  end
end


class ServerSocket
  def initialize(port,backlog,&on_connect)
    @listen_socket_fd = nil
  end

  def accept!
    
  end
end
