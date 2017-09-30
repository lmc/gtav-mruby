
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
  def width(astr)
    # get calculated string width
  end
end

class UiTable < Struct.new(:x, :y, :w, :h, :rh, :widths, :data, :p, :pco, :pci, :pro, :pri, :cell_text, :header_row_text, :body_row_text, :tr, :tg, :tb, :ta, :cr, :cg, :cb, :ca)
  def initialize(options = {})
    self.x      = options[:x]      || 0.3
    self.y      = options[:y]      || 0.3
    self.w      = options[:w]      || 0.3
    self.h      = options[:h]      || 0.3
    self.rh     = options[:rh]     || nil
    self.widths = options[:widths] || [ 1.0 ]
    self.data   = options[:data]   || [ ["UiTable"] ]
    self.p      = options[:p]      || 0.01
    self.pco    = options[:pco]    || 0.01
    self.pci    = options[:pci]    || 0.01
    self.pro    = options[:pro]    || 0.01
    self.pri    = options[:pri]    || 0.0
    self.tr     = options[:tr]     || 255
    self.tg     = options[:tg]     || 255
    self.tb     = options[:tb]     || 255
    self.ta     = options[:ta]     || 127
    self.cr     = options[:cr]     || 0
    self.cg     = options[:cg]     || 0
    self.cb     = options[:cb]     || 0
    self.ca     = options[:ca]     || 127
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
    if ta != 0
      GRAPHICS::DRAW_RECT(x + (w / 2), y + (h / 2), w, h, tr,tg,tb,ta)
    end
    data.each_with_index do |row,ri|
      row.each_with_index do |column,ci|
        cw = ((widths[ci] || 0.0) * (w - (p * 2 * sx) - ((pco * sx) * cols) + (pco * sx) ))
        xl = dx + (sx * pci)
        xr = dx + cw - (sx * pci)
        if ca != 0
          GRAPHICS::DRAW_RECT(dx + (cw / 2), dy + (drh / 2), cw, drh, cr,cg,cb,ca)
        end
        self.text_class_for(ri,ci,column).draw(data[ri][ci] || "",xl,dy + pri,xl,xr)
        dx += cw + (pco * sx)
      end
      dy += drh + pro
      dx = x + (p * sx)
    end
  end
  def text_class_for(ri,ci,val)
    if ri == 0
      header_row_text || cell_text
    else
      body_row_text || cell_text
    end
  end
end


class UiBarChart < Struct.new(:x, :y, :w, :h, :p, :limits, :bw, :data)
  def initialize(options = {})
    self.x         = options[:x]      || 0.33
    self.y         = options[:y]      || 0.33
    self.w         = options[:w]      || 0.33
    self.h         = options[:h]      || 0.33
    self.p         = options[:p]      || 0.01
    self.limits    = options[:limits] || [0.0,1.0]
    self.bw        = options[:bw]     || 0.0033
    self.data      = options[:data]   || []
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
        r,g,b,a = 255,0,0,127
      elsif d >= 0.004
        r,g,b,a = 255,255,0,127
      else
        r,g,b,a = 0,255,0,127
      end
      dh = ct + (val * h)
      dy = cb - (val * (h * 0.5))
      GRAPHICS::DRAW_RECT(x + (bw * i),dy,bw,dh,r,g,b,a)
    end
  end
end


# class UiMenu
#   @@_menu_id = 0
#   @@menus = {}
#   @@menu_selected = {}
#   @@menu_active = nil

#   def initialize(options = {})
#     @options = options.dup
#     @options[:x] = @options[:x] || 0.33
#     @options[:y] = @options[:y] || 0.33
#     @options[:w] = @options[:w] || 0.33
#     @options[:py] = @options[:py] || 0.002

#     @id = @options[:id] || "menu_#{@@_menu_id += 1}".to_sym
#     @table_options = @options.delete(:table_options) || {}
#     @table_options[:widths] = [1.0]
#     @table = UiTable.new(@table_options)
#     @selected = 0
#     @data = [["menu"]]
#     @visible = false
#     @@menus[@id] = self
#     @values = nil
#     @items = nil
#   end

#   def visible?; @visible; end
#   def visible=(v); @visible = v; end

#   def data; @data; end
#   def data=(v); @data = v; end

#   def selected; @selected; end
#   def selected=(v)
#     @selected = v
#     cap_selected!
#     @@menu_selected[@id] = @selected
#   end

#   def cap_selected!
#     if @first_item.nil?
#       @first_item = 0
#       @first_item = 1 if @items[0].is_a?(UiMenu::HeaderItem)
#     end
#     @selected = @first_item if @selected < @first_item
#     @selected = (@items.size - 1) if @selected >= (@items.size - 1)
#   end

#   def on_nav_left_pressed()
#     on_item_left_pressed(@selected)
#   end

#   def on_nav_right_pressed()
#     on_item_right_pressed(@selected)
#   end

#   def on_nav_up_pressed()
#     self.selected_adjust(-1)
#   end

#   def on_nav_down_pressed()
#     self.selected_adjust(+1)
#   end

#   def on_nav_select_pressed()
#     on_item_select_pressed(@selected)
#   end

#   def on_nav_back_pressed()
#     UiMenu.show
#   end

#   def draw
#     wx = @options[:x]
#     wy = @options[:y]
#     ww = @options[:w]
#     py = @options[:py]
#     # log "selected: #{@selected}"
#     @items.each_with_index do |item,i|
#       wy += item.draw(wx,wy,ww,@selected == i)
#       wy += py
#     end
#   end

#   def show(options)
#     @visible = true
#     values = options[:values] || {}
#     @values = self.defaults(values).dup.merge(values) if @values.nil?
#     build_items
#     cap_selected!
#     on_show()
#   end
#   def on_show()
#   end

#   def hide
#     @visible = false
#     on_hide()
#   end
#   def on_hide()
#   end

#   def selected_adjust(incr)
#     @selected += incr
#     cap_selected!
#   end

#   def on_item_select_pressed(selected)
    
#   end

#   def on_item_left_pressed(selected)
#     @items[@selected].on_left_pressed()
#   end

#   def on_item_right_pressed(selected)
#     @items[@selected].on_right_pressed()
#   end

#   def items
#     []
#   end

#   def defaults(values = {})
#     {}
#   end

#   def build_items
#     @items = []
#     self.items.each_with_index do |item,i|
#       @items << build_item(item,i)
#     end
#   end

#   def build_item(item,i)
#     case item[:type]
#     when :header
#       UiMenu::HeaderItem.new(self,item)
#     when :select
#       UiMenu::SelectItem.new(self,item)
#     when :button
#       UiMenu::ButtonItem.new(self,item)
#     end
#   end

#   def values
#     @values
#   end

#   def nav_up_pressed?
#     GTAV.is_key_just_up(Key::Up)         || GTAV.is_key_just_up(Key::NumPad8)
#   end
#   def nav_down_pressed?
#     GTAV.is_key_just_up(Key::Down)       || GTAV.is_key_just_up(Key::NumPad2)
#   end
#   def nav_left_pressed?
#     GTAV.is_key_just_up(Key::Left)       || GTAV.is_key_just_up(Key::NumPad4)
#   end
#   def nav_right_pressed?
#     GTAV.is_key_just_up(Key::Right)      || GTAV.is_key_just_up(Key::NumPad6)
#   end
#   def nav_select_pressed?
#     GTAV.is_key_just_up(Key::Enter)      || GTAV.is_key_just_up(Key::NumPad5)
#   end
#   def nav_back_pressed?
#     GTAV.is_key_just_up(Key::BackSpace)  || GTAV.is_key_just_up(Key::NumPad0)
#   end

#   def block_default_controls(block_controls = true)
#     CONTROLS::DISABLE_CONTROL_ACTION(0,Control::Phone,block_controls)
#   end

#   def self.any_visible?
#     !!active
#   end

#   def self.active
#     if @@menu_active
#       @@menus[@@menu_active]
#     else
#       nil
#     end
#   end

#   def handle_input
#     self.block_default_controls(true)
#     self.on_nav_left_pressed()   if self.nav_left_pressed?
#     self.on_nav_right_pressed()  if self.nav_right_pressed?
#     self.on_nav_select_pressed() if self.nav_select_pressed?
#     self.on_nav_back_pressed()   if self.nav_back_pressed?
#     self.on_nav_up_pressed()     if self.nav_up_pressed?
#     self.on_nav_down_pressed()   if self.nav_down_pressed?
#   end

#   def self.draw
#     if self.active
#       self.active.handle_input
#       self.active.draw
#     end
#   end

#   def self.show(id, options = {})
#     if self.active
#       self.active.hide()
#     end
#     @@menu_active = id
#     self.active.show(options)
#   end

#   def self.hide()
#     if self.active
#       self.active.hide()
#       @@menu_active = nil
#     end
#   end

#   def self.[](key)
#     @@menus[key]
#   end

#   class Item
#     def initialize(menu,options)
#       @menu = menu
#       @options = options
#     end

#     def draw(x,y,w,selected)
#       h = 0.05
#       return h
#     end

#     def value
#       @menu.values[ @options[:id] ]
#     end
#     def value=(v)
#       @menu.values[ @options[:id] ] = v
#     end

#     def on_left_pressed()
      
#     end

#     def on_right_pressed()
      
#     end
#   end

#   class HeaderItem < Item
#     def initialize(*)
#       super
#       @options[:text] = @options[:text] || UiStyledText.new(font: 1, scale2: 1.0)
#       @options[:label] = @options[:label] || "Header"
#     end
#     def draw(x,y,w,selected)
#       h = 0.1
#       px = 0.025
#       py = 0.025
#       GRAPHICS::DRAW_RECT(x + (w / 2), y + (h / 2), w, h, 64,64,255,255)
#       @options[:text].draw(@options[:label], x + px, y + py)
#       return h
#     end
#   end

#   class ButtonItem < Item
#     def initialize(*)
#       super
#       @options[:text] = @options[:text] || UiStyledText.new(font: 0, scale2: 0.3)
#       @options[:label] = @options[:label] || "Button"
#     end
#     def draw(x,y,w,selected)
#       h = 0.05
#       px = 0.025
#       py = 0.025
#       if selected
#         GRAPHICS::DRAW_RECT(x + (w / 2), y + (h / 2), w, h, 127,255,127,255)
#         @options[:text].draw(@options[:label], x + px, y + py)
#       else
#         GRAPHICS::DRAW_RECT(x + (w / 2), y + (h / 2), w, h, 127,127,127,255)
#         @options[:text].draw(@options[:label], x + px, y + py)
#       end
#       return h
#     end
#   end

#   class SelectItem < Item
#     def initialize(*)
#       super
#       @options[:text] = @options[:text] || UiStyledText.new(font: 0, scale2: 0.3)
#       @options[:label] = @options[:label] || "Button"
#       @options[:collection] = @options[:collection] || {0=>"0",1=>"1"}
#     end

#     def draw(x,y,w,selected)
#       h = 0.05
#       px = 0.025
#       py = 0.025
#       if selected
#         GRAPHICS::DRAW_RECT(x + (w / 2), y + (h / 2), w, h, 127,255,127,255)
#       else
#         GRAPHICS::DRAW_RECT(x + (w / 2), y + (h / 2), w, h, 127,127,127,255)
#       end
#       @options[:text].draw("#{@options[:label]}: #{self.value} #{@options[:collection].inspect}", x + px, y + py)
#       return h
#     end

#     def on_left_pressed()
#       index = @options[:collection].keys.index(value)
#       if @options[:collection].keys[index - 1]
#         self.value = @options[:collection].keys[index - 1]
#       end
#     end

#     def on_right_pressed()
#       index = @options[:collection].keys.index(value)
#       if @options[:collection].keys[index + 1]
#         self.value = @options[:collection].keys[index + 1]
#       else
#         self.value = @options[:collection].keys[0]
#       end
#     end
#   end

# end


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
