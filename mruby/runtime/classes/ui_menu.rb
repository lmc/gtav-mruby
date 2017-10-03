
# NEXT:
# menu builder syntax?
# better log viewer
# can instrumentation be made faster?
# create item instances directly instead of passing options hashes around?
# backtraces are still missing first item - fixed in mruby 1.3?
# allow you to hold buttons down for menu items
# display a value on buttons
# hide top/bottom header bars
# convert colours and measurements to constants or menu/item vars
# proper checkbox from CommonMenu (shop_box_tick)
# rgb picker
# text item - for noninteractive display
# column support for text/icons

class UiMenu
  @@_menu_id = 0
  @@menus = {}
  @@menu_selected = {}
  @@menu_active = nil
  @@menus_visible = []

  def initialize(options = {})
    @options = options.dup
    @options[:x] = @options[:x] || 0.0265
    @options[:y] = @options[:y] || 0.02475
    @options[:w] = @options[:w] || 0.2245
    @options[:py] = @options[:py] || 0.002
    @options[:max_rows] = @options[:max_rows] || 10

    @id = @options[:id] || "menu_#{@@_menu_id += 1}".to_sym

    @table_options = @options.delete(:table_options) || {}
    @table_options[:widths] = [1.0]
    @table = UiTable.new(@table_options)
    @data = [["menu"]]

    @selected = 0
    @scroll = 0

    
    @visible = false
    @values = nil
    @items = nil
    @next_update = 0

    @@menus[@id] = self
  end

  def visible?; @visible; end
  def visible=(v); @visible = v; end

  def data; @data; end
  def data=(v); @data = v; end

  def selected; @selected; end
  def selected=(v)
    @selected = v
    cap_selected!
    @@menu_selected[@id] = @selected
  end

  def scroll; @scroll; end
  def scroll=(v)
    @scroll = v
  end

  def options
    @options
  end

  def selected_value
    return nil if !@items[@selected]
    if self.items[@selected][:type] == :button
       self.items[@selected][:value]
    else
      @values[ self.items[@selected][:id] ]
    end
  end

  def cap_selected!(first_on_invalid = false)
    return if !@selected

    if @first_item.nil?
      @first_item = 0
      @first_item = 1 if has_header?
      @last_item = @items.size - 1
      @last_item -= 1 if has_help?
    end
     
    if @selected < @first_item
      @selected = first_on_invalid ? @first_item : @last_item
    end
    if @selected > @last_item
      @selected = @first_item
    end

    @scroll = @selected if @scroll > @selected
    @scroll = @selected - @options[:max_rows] + 1 if @scroll <= @selected - @options[:max_rows] + 1

    @scroll = @first_item if @scroll < @first_item
    @scroll = @last_item if @scroll >= @last_item
  end
  
  def first_item
    @first_item
  end
  def item_count
    count = @items.size
    count -= 1 if has_header?
    count -= 1 if has_help?
    count
  end

  def has_header?
    @items[0].is_a?(UiMenu::HeaderItem)
  end

  def has_help?
    @items[-1].is_a?(UiMenu::HelpItem)
  end

  def on_nav_left_pressed()
    on_item_left_pressed()
  end

  def on_nav_right_pressed()
    on_item_right_pressed()
  end

  def on_nav_up_pressed()
    self.selected_adjust(-1)
  end

  def on_nav_down_pressed()
    self.selected_adjust(+1)
  end

  def on_nav_select_pressed()
    on_item_select_pressed()
  end

  def on_nav_back_pressed()
    UiMenu.hide
  end

  def draw(ax = nil, ay = nil, aw = nil)
    wx = ax || @options[:x]
    wy = ay || @options[:y]
    ww = aw || @options[:w]
    py = @options[:py]
    if item_count > @options[:max_rows]
      wy += @items[0].draw(wx,wy,ww,false) if has_header?
      @scroll.upto(@scroll + @options[:max_rows] - 1) do |i|
        wy += @items[i].draw(wx,wy,ww,@selected == i)
      end
      wy += draw_scroll_item(wx,wy,ww)
      wy += @items[-1].draw(wx,wy,ww,false) if has_help?
    else
      @items.each_with_index do |item,i|
        wy += item.draw(wx,wy,ww,@selected == i)
      end
    end
  end

  def show(options)
    @visible = true
    values = options[:values] || @values || {}
    @values = self.defaults(values).dup.merge(values)
    build_items
    @selected = options[:selected] if options.key?(:selected)
    cap_selected!(true)
    update_help
    on_show()
  end
  def on_show()
  end

  def hide
    @visible = false
    on_hide()
  end
  def on_hide()
  end

  def on_show_submenu(*)
    
  end

  def parent
    if idx = @@menus_visible.index(@id)
      id = @@menus_visible[idx - 1]
      @@menus[id]
    end
  end

  def selected_adjust(incr)
    @selected += incr
    cap_selected!
    update_help
  end

  def update_help
    return if !@selected
    if @items[-1].is_a?(UiMenu::HelpItem)
      @items[-1].update_help(@items[@selected])
    end
  end
  
  @@symbols_text = nil
  def self.symbols_text
    if !@@symbols_text
      @@symbols_text = ::UiStyledText.new(font: 3, scale2: 0.25, alignment: 0, r: 255, g: 255, b: 255, a: 255)
    end
    @@symbols_text
  end

  def draw_scroll_item(x,y,w)
    h = 0.03
    my = 0.002
    py = 0.005
    pya = 0.0025
    GRAPHICS::DRAW_RECT(x + (w / 2), y + my + (h / 2), w, h, 0,0,0,127)
    UiMenu.symbols_text.rgba = RGBA(255,255,255,255)
    UiMenu.symbols_text.scale2 = 0.25
    UiMenu.symbols_text.draw("3",x + (w / 2), y + py - pya, x, x + w)
    UiMenu.symbols_text.draw("4",x + (w / 2), y + py + pya, x, x + w)
    
    # text = ::UiStyledText.new(font: 5, scale2: 0.25)
    # text.scale2 = 0.25
    # text.draw("1234567890qwertyuiopasdfghjklzxcvbnm",x + (w / 2) + 0.5, y + py + pya, )
    return h + my
  end

  def on_item_select_pressed()
    @items[@selected].on_select_pressed()
    update_items
  end

  def on_item_left_pressed()
    @items[@selected].on_left_pressed()
    update_items
  end

  def on_item_right_pressed()
    @items[@selected].on_right_pressed()
    update_items
  end

  def items
    []
  end

  def defaults(values = {})
    {}
  end

  def build_items
    @items = []
    self.items.each_with_index do |item,i|
      @items << build_item(item,i)
    end
  end

  def build_item(item,i)
    case item[:type]
    when :header
      UiMenu::HeaderItem.new(self,item)
    when :select
      UiMenu::SelectItem.new(self,item)
    when :checkbox
      UiMenu::CheckboxItem.new(self,item)
    when :button
      UiMenu::ButtonItem.new(self,item)
    when :help
      UiMenu::HelpItem.new(self,item)
    when :list
      UiMenu::ListItem.new(self,item)
    when :integer
      UiMenu::IntegerItem.new(self,item)
    when :float
      UiMenu::FloatItem.new(self,item)
    end
  end

  def update_items
    @items.each(&:update)
  end

  def _items
    @items
  end

  def values
    @values
  end

  def nav_up_pressed?
    GTAV.is_key_just_up(Key::Up)        || GTAV.is_key_just_up(Key::NumPad8) || CONTROLS::IS_CONTROL_JUST_RELEASED(0,Control::PhoneUp)
  end
  def nav_down_pressed?
    GTAV.is_key_just_up(Key::Down)      || GTAV.is_key_just_up(Key::NumPad2) || CONTROLS::IS_CONTROL_JUST_RELEASED(0,Control::PhoneDown)
  end
  def nav_left_pressed?
    GTAV.is_key_just_up(Key::Left)      || GTAV.is_key_just_up(Key::NumPad4) || CONTROLS::IS_CONTROL_JUST_RELEASED(0,Control::PhoneLeft)
  end
  def nav_right_pressed?
    GTAV.is_key_just_up(Key::Right)     || GTAV.is_key_just_up(Key::NumPad6) || CONTROLS::IS_CONTROL_JUST_RELEASED(0,Control::PhoneRight)
  end
  def nav_select_pressed?
    GTAV.is_key_just_up(Key::Enter)     || GTAV.is_key_just_up(Key::NumPad5) || CONTROLS::IS_CONTROL_JUST_RELEASED(0,Control::PhoneSelect)
  end
  def nav_back_pressed?
    GTAV.is_key_just_up(Key::BackSpace) || GTAV.is_key_just_up(Key::NumPad0) || CONTROLS::IS_CONTROL_JUST_RELEASED(0,Control::PhoneCancel)
  end

  def block_default_controls(block_controls = true)
    CONTROLS::DISABLE_CONTROL_ACTION(0,Control::Phone,block_controls)
    CONTROLS::DISABLE_CONTROL_ACTION(0,Control::HUDSpecial,block_controls)
    CONTROLS::DISABLE_CONTROL_ACTION(0,Control::MeleeAttackLight,block_controls)
    CONTROLS::DISABLE_CONTROL_ACTION(0,Control::VehicleRadioWheel,block_controls)
    CONTROLS::DISABLE_CONTROL_ACTION(0,Control::VehicleCinCam,block_controls)
    CONTROLS::DISABLE_CONTROL_ACTION(0,Control::VehicleHeadlight,block_controls)
    # doesn't seem to block this
    # CONTROLS::DISABLE_CONTROL_ACTION(0,Control::InteractionMenu,block_controls)
  end

  def self.any_visible?
    !!active
  end

  def self.active
    if @@menu_active
      @@menus[@@menu_active]
    else
      nil
    end
  end

  def handle_input
    self.block_default_controls(true)
    self.on_nav_left_pressed()   if self.nav_left_pressed?
    self.on_nav_right_pressed()  if self.nav_right_pressed?
    self.on_nav_select_pressed() if self.nav_select_pressed?
    self.on_nav_back_pressed()   if self.nav_back_pressed?
    self.on_nav_up_pressed()     if self.nav_up_pressed?
    self.on_nav_down_pressed()   if self.nav_down_pressed?
    if GTAV.time > @next_update
      update_items
      @next_update = GTAV.time + 250
    end
  end

  def self.draw
    self.active.handle_input if self.active
    # the active menu can go away in response to input, so check again
    @@menus_visible.each do |key|
      @@menus[key].draw
    end
  end

  def self.show(id, options = {})
    @@menus_visible.each do |key|
      @@menus[key].hide()
    end
    @@menu_active = id
    @@menus_visible = [id]
    self.active.show(options)
  end

  def self.show_submenu(id, options = {})
    current = self.active
    current.on_show_submenu(id,options)
    @@menu_active = id
    @@menus_visible << id
    self.active.options[:x] = current.options[:x] + current.options[:w] + 0.01
    self.active.show(options)
  end

  def self.hide()
    if self.active
      self.active.hide()
      @@menus_visible.delete(@@menu_active)
      @@menu_active = nil
    end
  end

  def self.hide_submenu()
    id = @@menus_visible[-1]
    @@menus[id].hide()
    @@menus_visible.delete(id)
    @@menu_active = @@menus_visible[-1]
  end

  def self.[](key)
    @@menus[key]
  end

  def self.draw_menu_arrow(dir,r,g,b,a)
    
  end

end
