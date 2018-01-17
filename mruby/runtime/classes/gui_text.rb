
# Text symbols:
# ~a~ - nothing ?
# ~b~ - blue
# ~c~ - grey
# ~d~ - dark dark blue/green?
# ~e~ - normal?
# ~f~ - light blue
# ~g~ - green
# ~h~ - bold
# ~i~ - nothing?
# ~j~ - nothing?
# ~k~ - nothing?
# ~l~ - black
# ~m~ - grey or semi-transparent?
# ~n~ - new line
# ~o~ - orange
# ~p~ - purple
# ~q~ - magenta
# ~r~ - red
# ~s~ - nothing? - reset?
# ~t~ - grey or semi-transparent?
# ~u~ - black
# ~v~ - black
# ~w~ - nothing?
# ~x~ - nothing?
# ~y~ - yellow
# ~z~ - nothing?
class GUI::Text < Struct.new(:font, :scale1, :scale2, :r, :g, :b, :a, :alignment, :wrap_x, :wrap_y, :proportional, :str, :x, :y)
  def initialize(options = {})
    self.font         = options[:font]         || 0
    self.scale1       = options[:scale1]       || 0.0
    self.scale2       = options[:scale2]       || 0.5

    self.r            = options[:r]            || 255
    self.g            = options[:g]            || 255
    self.b            = options[:b]            || 255
    self.a            = options[:a]            || 255
    self.rgba         = options[:rgba] if options[:rgba]

    self.alignment    = options[:alignment]    || 1
    self.wrap_x       = options[:wrap_x]       || 0.0
    self.wrap_y       = options[:wrap_y]       || 1.0
    self.proportional = options.key?(:proportional) ? options[:proportional] : true
    self.str          = options[:str]
    self.x            = options[:x]
    self.y            = options[:y]
  end

  # NOTE: can only draw 0..98 chars at once
  def draw(astr = nil, ax = nil, ay = nil, awrap_x = nil, awrap_y = nil)
    self.str = astr if astr
    self.x = ax if ax
    self.y = ay if ay
    self.wrap_x = awrap_x if awrap_x
    self.wrap_y = awrap_y if awrap_y
    raise ArgumentError if !x || !y || !str
    GTAV._draw_text_many(*self)
  end

  def width(astr = nil, ax = nil, ay = nil, awrap_x = nil, awrap_y = nil)
    UI::_SET_TEXT_ENTRY_FOR_WIDTH("STRING")
    UI::SET_TEXT_FONT(font)
    UI::SET_TEXT_SCALE(scale1, scale2)
    UI::SET_TEXT_WRAP(awrap_x || wrap_x, awrap_y || wrap_y)
    UI::SET_TEXT_PROPORTIONAL(proportional)
    UI::_ADD_TEXT_COMPONENT_STRING(astr || str)
    UI::_GET_TEXT_SCREEN_WIDTH(1)
  end

  def rows(astr = nil, ax = nil, ay = nil, awrap_x = nil, awrap_y = nil)
    UI::_SET_TEXT_GXT_ENTRY("STRING")
    UI::SET_TEXT_FONT(font)
    UI::SET_TEXT_SCALE(scale1, scale2)
    UI::SET_TEXT_WRAP(awrap_x || wrap_x, awrap_y || wrap_y)
    UI::SET_TEXT_PROPORTIONAL(proportional)
    UI::_ADD_TEXT_COMPONENT_STRING(astr || str)
    UI::_0x9040DFB09BE75706(ax || x, ay || y)
  end

  def rgba(value = nil)
    if value
      self.rgba = value
      return self
    else
      RGBA.new(r,g,b,a)
    end
  end

  def rgba=(args)
    self.r = args[0]
    self.g = args[1]
    self.b = args[2]
    self.a = args[3]
  end
end

GUI::Text = GUI::Text
