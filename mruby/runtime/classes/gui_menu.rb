
# NEXT:
# menu builder syntax?
# better log viewer
# can instrumentation be made faster?
# create item instances directly instead of passing options hashes around?
# allow you to hold buttons down for menu items
# convert colours and measurements to constants or menu/item vars
# proper checkbox from CommonMenu (shop_box_tick)
# rgb picker
# text item - for noninteractive display
# every(250.ms){ periodic_thing() } # execute every 250ms
# method to get prioritised colours for active/selected/disabled/etc.
# take over interaction menu too (it doesn't do much in singleplayer)

class GUI::Menu
  @@_menu_id = 0
  @@menus = {}
  @@menu_selected = {}
  @@menu_active = nil
  @@menus_visible = []

  @@themes = {}
  @@themes[:default] = {}
  @@active_theme = :default

  @@default_parent = nil

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

    @@themes[:default][:text_item] = GUI::Text.new(font: 0, scale2: 0.325)
    @@themes[:default][:text_icons] = GUI::Text.new(font: 3, scale2: 0.25, alignment: 0, r: 255, g: 255, b: 255, a: 255)
    @@themes[:default][:text_header] = GUI::Text.new(font: 1, scale2: 1.1, alignment: 0)
    @@themes[:default][:colour_item_text] = RGBA(255,255,255,255)
    @@themes[:default][:colour_item_bg]   = RGBA(  0,  0,  0,127)
    @@themes[:default][:colour_item_selected_text] = RGBA(  0,  0,  0,255)
    @@themes[:default][:colour_item_selected_bg]   = RGBA(240,240,240,255)
    @@themes[:default][:colour_item_disabled_text] = RGBA(220,220,220,220)
    @@themes[:default][:colour_item_disabled_selected_text] = RGBA( 60, 60, 60,255)

    GRAPHICS::REQUEST_STREAMED_TEXTURE_DICT("CommonMenu",false)
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
    return if !@selected || !@items

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
    @items[0].is_a?(GUI::Menu::HeaderItem)
  end

  def has_help?
    @items[-1].is_a?(GUI::Menu::HelpItem)
  end

  def on_nav_left_pressed()
    AUDIO::PLAY_SOUND_FRONTEND(-1,"NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0)
    on_item_left_pressed()
  end

  def on_nav_right_pressed()
    AUDIO::PLAY_SOUND_FRONTEND(-1,"NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0)
    on_item_right_pressed()
  end

  def on_nav_up_pressed()
    AUDIO::PLAY_SOUND_FRONTEND(-1,"NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0)
    self.selected_adjust(-1)
  end

  def on_nav_down_pressed()
    AUDIO::PLAY_SOUND_FRONTEND(-1,"NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0)
    self.selected_adjust(+1)
  end

  def on_nav_select_pressed()
    AUDIO::PLAY_SOUND_FRONTEND(-1,"SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0)
    on_item_select_pressed()
  end

  def on_nav_back_pressed()
    AUDIO::PLAY_SOUND_FRONTEND(-1,"CANCEL", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0)
    parent = @options[:parent] || @@default_parent
    if parent
      GUI::Menu.show(parent)
    else
      GUI::Menu.hide
    end
  end

  def draw_instructional_buttons
    # GAME BUG: if multiple scripts load this scaleform movie, ours will not show
    # text/buttons until the other script calls SET_SCALEFORM_MOVIE_AS_NO_LONGER_NEEDED
    # 
    @@instructional_buttons_scaleform ||= GRAPHICS::REQUEST_SCALEFORM_MOVIE("instructional_buttons")
    if GRAPHICS::HAS_SCALEFORM_MOVIE_LOADED(@@instructional_buttons_scaleform)
      instructional_buttons = nil
      if @selected && @items[@selected]
        instructional_buttons = @items[@selected].instructional_buttons
      end
      instructional_buttons ||= default_instructional_buttons
      instructional_buttons.draw(@@instructional_buttons_scaleform)
    end
  end

  def default_instructional_buttons
    helper = GUI::InstructionalButtons.new
    helper.add("Up/Down",button: :DPAD_UP_DOWN)
    helper.add("Select",input: Control::PhoneSelect)
    helper.add("Cancel",input: Control::PhoneCancel)
    helper
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
    refresh(options)
    on_show()
  end
  def on_show()
  end

  def hide
    GRAPHICS::SET_SCALEFORM_MOVIE_AS_NO_LONGER_NEEDED(@@instructional_buttons_scaleform) if @@instructional_buttons_scaleform
    @@instructional_buttons_scaleform = nil
    @visible = false
    on_hide()
  end
  def on_hide()
  end

  def on_show_submenu(*)
    
  end

  def refresh(options = {})
    build_items
    @first_item = @last_item = nil
    @selected = options[:selected] if options.key?(:selected)
    cap_selected!(true)
    update_help
  end

  def parent
    if idx = @@menus_visible.index(@id)
      id = @@menus_visible[idx - 1]
      @@menus[id]
    end
  end

  def selected_adjust(incr)
    return if !@selected
    @selected += incr
    cap_selected!
    update_help
  end

  def update_help
    # return if !@selected
    if @items[-1].is_a?(GUI::Menu::HelpItem)
      selected = @selected ? @items[@selected] : nil
      @items[-1].update_help(selected)
    end
  end
  
  @@symbols_text = nil
  def self.symbols_text
    if !@@symbols_text
      @@symbols_text = ::GUI::Text.new(font: 3, scale2: 0.25, alignment: 0, r: 255, g: 255, b: 255, a: 255)
    end
    @@symbols_text
  end

  def draw_scroll_item(x,y,w)
    h = 0.03
    my = 0.002
    py = 0.005
    pya = 0.0025
    GRAPHICS::DRAW_RECT(x + (w / 2), y + my + (h / 2), w, h, 0,0,0,127)
    GUI::Menu.symbols_text.rgba = RGBA(255,255,255,255)
    GUI::Menu.symbols_text.scale2 = 0.25
    GUI::Menu.symbols_text.draw("3",x + (w / 2), y + py - pya, x, x + w)
    GUI::Menu.symbols_text.draw("4",x + (w / 2), y + py + pya, x, x + w)
    
    # text = ::GUI::Text.new(font: 5, scale2: 0.25)
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
  
  def on_item_right_pressed(&block)
    @items[@selected].on_right_pressed()
    update_items
  end
  
  @_items = nil
  def items(&block)
    if block_given?
      @_items = block
    else
      if @_items
        ret = []
        @_items.call(ret)
        ret
      else
        []
      end
    end
  end

  def defaults(values = {},&block)
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
      HeaderItem.new(self,item)
    when :select
      SelectItem.new(self,item)
    when :checkbox
      CheckboxItem.new(self,item)
    when :button
      ButtonItem.new(self,item)
    when :help
      HelpItem.new(self,item)
    when :list
      ListItem.new(self,item)
    when :integer
      IntegerItem.new(self,item)
    when :float
      FloatItem.new(self,item)
    when :colour
      ColourItem.new(self,item)
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
  
  
  DEFAULT_BOUNCE_TIME = 250
  def get_input_state(input,key_value)
    @input_states ||= Hash.new{|h,k| h[k] = { pressed: false, for: 0, bounced: DEFAULT_BOUNCE_TIME, bounce_time: DEFAULT_BOUNCE_TIME } }
    pressed_now = !key_value ? CONTROLS::IS_DISABLED_CONTROL_PRESSED(0,input) : key_value
    # if key is down, returns negative ms
    if @input_states[input][:pressed] && !pressed_now
      @input_states[input][:pressed] = false
      r = @input_states[input][:for]
      @input_states[input][:for] = 0
      return r
    elsif pressed_now
      @input_states[input][:pressed] = true
      @input_states[input][:for] += 1000 * SYSTEM::TIMESTEP()
      return -@input_states[input][:for]
    else
      @input_states[input][:pressed] = false
      0
    end
  end
  
  def tap_or_scroll(input,key_value = nil)
    input_state = get_input_state(input,key_value)
    if input_state == 0
      return false
    elsif input_state > 0
      @input_states[input][:bounce_time] = DEFAULT_BOUNCE_TIME
      @input_states[input][:bounced] = DEFAULT_BOUNCE_TIME
      if input_state > DEFAULT_BOUNCE_TIME
        return false
      else
        return true
      end
    elsif @input_states[input][:bounced] <= 0
      @input_states[input][:bounced] = @input_states[input][:bounce_time]
      if @input_states[input][:bounce_time] > 10.0
        @input_states[input][:bounce_time] /= 1.15
      end
      return true
    elsif @input_states[input][:bounced] > 0
      @input_states[input][:bounced] -= 1000 * SYSTEM::TIMESTEP()
      return false
    else
      return false
    end
  end

  def nav_up_pressed?
    tap_or_scroll(Control::PhoneUp,GTAV.is_key_down(Key::Up))
    # GTAV.is_key_just_up(Key::Up)        || GTAV.is_key_just_up(Key::NumPad8) || CONTROLS::IS_CONTROL_JUST_RELEASED(0,Control::PhoneUp)
  end
  def nav_down_pressed?
    tap_or_scroll(Control::PhoneDown,GTAV.is_key_down(Key::Down))
    # GTAV.is_key_just_up(Key::Down)      || GTAV.is_key_just_up(Key::NumPad2) || CONTROLS::IS_CONTROL_JUST_RELEASED(0,Control::PhoneDown)
  end
  def nav_left_pressed?
    tap_or_scroll(Control::PhoneLeft,GTAV.is_key_down(Key::Left))
    # GTAV.is_key_just_up(Key::Left)      || GTAV.is_key_just_up(Key::NumPad4) || CONTROLS::IS_CONTROL_JUST_RELEASED(0,Control::PhoneLeft)
  end
  def nav_right_pressed?
    tap_or_scroll(Control::PhoneRight,GTAV.is_key_down(Key::Right))
    # GTAV.is_key_just_up(Key::Right)     || GTAV.is_key_just_up(Key::NumPad6) || CONTROLS::IS_CONTROL_JUST_RELEASED(0,Control::PhoneRight)
  end
  def nav_select_pressed?
    # tap_or_scroll(Control::PhoneSelect,GTAV.is_key_down(Key::Enter))
    GTAV.is_key_just_up(Key::Enter)     || GTAV.is_key_just_up(Key::NumPad5) || CONTROLS::IS_CONTROL_JUST_RELEASED(0,Control::PhoneSelect)
  end
  def nav_back_pressed?
    # tap_or_scroll(Control::PhoneCancel,GTAV.is_key_down(Key::BackSpace))
    GTAV.is_key_just_up(Key::BackSpace) || GTAV.is_key_just_up(Key::NumPad0) || CONTROLS::IS_CONTROL_JUST_RELEASED(0,Control::PhoneCancel)
  end

  def block_default_controls(block_controls = true)
    # clear notifications
    UI::_0x55598D21339CB998(1.0)

    # CONTROLS::DISABLE_CONTROL_ACTION(0,Control::CharacterWheel,block_controls)

    CONTROLS::DISABLE_CONTROL_ACTION(0,Control::Phone,block_controls)
    CONTROLS::DISABLE_CONTROL_ACTION(0,Control::HUDSpecial,block_controls)
    CONTROLS::DISABLE_CONTROL_ACTION(0,Control::Detonate,block_controls)

    if PED::IS_PED_IN_ANY_VEHICLE(PLAYER::PLAYER_PED_ID(),false)
      CONTROLS::DISABLE_CONTROL_ACTION(0,Control::VehicleRadioWheel,block_controls)
      CONTROLS::DISABLE_CONTROL_ACTION(0,Control::VehicleCinCam,block_controls)
      CONTROLS::DISABLE_CONTROL_ACTION(0,Control::VehicleHeadlight,block_controls)
      CONTROLS::DISABLE_CONTROL_ACTION(0,Control::VehicleFlyVerticalFlightMode,block_controls)
      CONTROLS::DISABLE_CONTROL_ACTION(0,Control::VehicleRoof,block_controls)
    else
      CONTROLS::DISABLE_CONTROL_ACTION(0,Control::MeleeAttackLight,block_controls)
      CONTROLS::DISABLE_CONTROL_ACTION(0,Control::Context,block_controls)
      CONTROLS::DISABLE_CONTROL_ACTION(0,Control::Talk,block_controls)
    end
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
    if self.active
      self.active.draw_instructional_buttons
      self.active.handle_input
    end
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

    # HACK: prevent replay popup from appearing when holding dpad-down by
    # killing the entire character selector script (and restarting it on hide)
    terminate_script_named("selector")
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

    # HACK: restart character selector script when we close
    SYSTEM::START_NEW_SCRIPT("selector", 1424) if SCRIPT::_GET_NUMBER_OF_INSTANCES_OF_STREAMED_SCRIPT(GAMEPLAY::GET_HASH_KEY("selector")) == 0
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

  def self.theme(key)
    @@themes[@@active_theme][key]
  end

end

GUI::Menu = GUI::Menu
