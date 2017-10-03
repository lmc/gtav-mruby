
class UiMenu

  class Item
    def initialize(menu,options)
      @menu = menu
      @options = options
      @enabled = true
      self.value = option_value(:default) if @options.key?(:default) && self.value.nil?
      self.value = @options[:value] if @options.key?(:value)
      update
    end

    def draw(x,y,w,selected)
      h = 0.05
      return h
    end

    def update
      @enabled = option_value(:enabled,true)
    end

    def value
      return nil if !@options[:id]
      @menu.values[ @options[:id] ]
    end
    def value=(v)
      return nil if !@options[:id]
      @menu.values[ @options[:id] ] = v
    end

    def options
      @options
    end

    def id
      @options[:id]
    end

    def menu
      @menu
    end

    def enabled?
      @enabled
    end

    def on_select_pressed()
      
    end

    def on_left_pressed()
      
    end

    def on_right_pressed()
      
    end

    def option_value(key, default = nil)
      if @options[key].is_a?(Proc)
        @options[key].call(self)
      elsif @options.key?(key)
        @options[key]
      else
        default
      end
    end
  end

  class HeaderItem < Item
    def initialize(*)
      super
      @options[:text] = @options[:text] || UiStyledText.new(font: 1, scale2: 1.1, alignment: 0)
      @options[:text_sub_l] = @options[:text_sub_l] || UiStyledText.new(font: 0, scale2: 0.325)
      @options[:text_sub_r] = @options[:text_sub_r] || UiStyledText.new(font: 0, scale2: 0.325, alignment: 3)
      @options[:label] = @options[:label] || "Header"
      @options[:label_sub] = @options[:label_sub] || ""
    end
    def draw(x,y,w,selected)
      h = 0.101
      wx = x
      wy = y
      px = 0.0125
      py = 0.02
      GRAPHICS::DRAW_RECT(wx + (w / 2), wy + (h / 2), w, h, 15,110,184,255)
      @options[:text].draw(@options[:label], wx + px + ((w - (px * 2)) / 2), wy + py, wx + px, (wx + w) - px)
      if @options[:label_sub]
        oh = h
        wy += oh
        h = 0.0345
        px = 0.0044
        py = 0.004
        GRAPHICS::DRAW_RECT(wx + (w / 2), wy + (h / 2), w, h, 0,0,0,255)
        @options[:text_sub_l].draw(@options[:label_sub], wx + px, wy + py)
        @options[:text_sub_r].draw("#{@menu.selected} / #{@menu.item_count}", (wx + (w/2)) - px, wy + py, wx + px, (wx + w) - px)
        return oh + h
      end
      return h
    end
  end

  class HelpItem < Item
    def initialize(*)
      super
      @options[:text] = @options[:text] || UiStyledText.new(font: 0, scale2: 0.325)
      @cached_lines = nil
    end

    def draw(x,y,w,selected)
      cache_lines if !@cached_lines
      return 0.0 if @cached_lines.size == 0
      my = 0.004
      # h = 0.08
      wx = x
      wy = y + my
      p = 0.0025
      px = 0.0044
      py = 0.005
      lh = 0.02
      tlh = 0.002

      lines_per_line = []
      lines_total = 0
      @cached_lines.each_with_index do |line,i|
        rows = @options[:text].rows("#{line}", wx + px, wy + py + (lh * 0), wx + px, (wx + w) - px)
        lines_per_line << rows
        lines_total += rows
      end

      h = (lh * lines_total) + (py * 2) + (p * 2)

      GRAPHICS::DRAW_RECT(wx + (w / 2), wy + (h / 2), w, h, 0,0,0,127)
      GRAPHICS::DRAW_RECT(wx + (w / 2), wy + (tlh / 2), w, tlh, 0,0,0,255)
      @options[:text].r = @options[:text].g = @options[:text].b = 255

      row = 0
      @cached_lines.each_with_index do |line,i|
        rows = lines_per_line[i]
        @options[:text].draw("#{line}", wx + px, wy + py + (lh * row), wx + px, (wx + w) - px)
        row += rows
      end
      return h + my
    end

    def update
      super
      update_help(@menu.instance_eval("@items")[@menu.selected])
    end

    def update_help(item)
      @value = item.option_value(:help) || option_value(:default) || ""
      # @value += "\n\n#{@menu.values.inspect}"
      cache_lines
    end
    
    def cache_lines
      @cached_lines = []
      return if !@value
      lines = @value.split("\n")
      lines.each_with_index do |line,i|
        # log "size: #{line.size} - #{line}"
        if line.size > 98
          lines[i + 1] = "" if !lines[i + 1]
          lines[i + 1] = line[99..-1]+lines[i + 1]
          line = line[0..98]
        end
        @cached_lines << line
      end
    end
  end

  class ButtonItem < Item
    def initialize(*)
      super
      @options[:text] = @options[:text] || UiStyledText.new(font: 0, scale2: 0.325)
      @options[:label] = @options[:label] || "Button"
      @value = option_value(:value,nil)
    end
    def draw(x,y,w,selected)
      h = 0.0345
      px = 0.0044
      py = 0.004

      @options[:text].a = 255

      if selected
        GRAPHICS::DRAW_RECT(x + (w / 2), y + (h / 2), w, h, 240,240,240,255)
        @options[:text].r = @options[:text].g = @options[:text].b = 0
      else
        GRAPHICS::DRAW_RECT(x + (w / 2), y + (h / 2), w, h, 0,0,0,127)
        @options[:text].r = @options[:text].g = @options[:text].b = 255
      end
      
      if !enabled?
        if selected
          @options[:text].rgba = RGBA(64,64,64,192)
        else
          @options[:text].rgba = RGBA(192,192,192,255)
        end
      end
      @options[:text].draw(@options[:label], x + px, y + py)

      if @options[:right_action]
        # @options[:text].draw(">", (x + w) - px - 0.01, y + py)
        UiMenu.symbols_text.rgba = @options[:text].rgba
        UiMenu.symbols_text.draw("2",(x + w) - px - 0.005, y + py)
      end

      return h
    end

    def on_select_pressed()
      return if !@enabled
      @options[:action].call(self) if @options[:action]
      nil
    end

    def on_right_pressed
      return if !@enabled
      @options[:right_action].call(self) if @options[:right_action]
      nil
    end
  end

  class SelectItem < Item
    def initialize(*)
      super
      @options[:text_label] = @options[:text_label] || UiStyledText.new(font: 0, scale2: 0.325)
      # @options[:text_value] = @options[:text_value] || UiStyledText.new(font: 2, scale2: 0.3, alignment: 3)
      @options[:text_value] = @options[:text_value] || UiStyledText.new(font: 0, scale2: 0.325, alignment: 3)
      @options[:label] = @options[:label] || "Button"
      @options[:collection] = @options[:collection] || {0=>"0",1=>"1"}
    end

    def draw(x,y,w,selected)
      h = 0.0345
      px = 0.0044
      py = 0.004
      if selected
        GRAPHICS::DRAW_RECT(x + (w / 2), y + (h / 2), w, h, 240,240,240,255)
        @options[:text_label].rgba = [0,0,0,255]
        @options[:text_value].rgba = [0,0,0,255]
      else
        GRAPHICS::DRAW_RECT(x + (w / 2), y + (h / 2), w, h, 0,0,0,127)
        @options[:text_label].rgba = RGBA(255,255,255,255)
        @options[:text_value].rgba = RGBA(255,255,255,255)
      end

      @options[:text_label].draw("#{@options[:label]}", x + px, y + py)
      
      value = display_value()
      if selected
        # @options[:text_value].draw("< #{@options[:collection][self.value] || self.value.inspect} >", (x + (w/2)) - px, y + py, x + px, (x + w) - px)
        UiMenu.symbols_text.rgba = @options[:text_value].rgba
        UiMenu.symbols_text.draw("2",(x + w) - px - 0.005, y + py)
        @options[:text_value].draw(value, (x + (w/2)) - px, y + py, x + px, (x + w) - px - 0.01)
        tw = @options[:text_value].width(value, (x + (w/2)) - px, y + py, x + px, (x + w) - px - 0.01)
        UiMenu.symbols_text.draw("1",(x + w) - px - 0.01 - tw - 0.004, y + py)
      else
        @options[:text_value].draw(value, (x + (w/2)) - px, y + py, x + px, (x + w) - px - 0.0)
      end         
      return h
    end

    def display_value()
      "#{@options[:collection][self.value] || self.value.inspect}"
    end

    def on_select_pressed()
      on_right_pressed()
    end

    def on_left_pressed()
      index = @options[:collection].keys.index(value)
      if !@options[:collection].keys[index - 1].nil?
        self.value = @options[:collection].keys[index - 1]
        @options[:action].call(self) if @options[:action]
      end
    end

    def on_right_pressed()
      index = @options[:collection].keys.index(value)
      if !@options[:collection].keys[index + 1].nil?
        self.value = @options[:collection].keys[index + 1]
        @options[:action].call(self) if @options[:action]
      else
        self.value = @options[:collection].keys[0]
        @options[:action].call(self) if @options[:action]
      end
    end
  end

  class CheckboxItem < SelectItem
    def initialize(*)
      super
      @options[:collection] = {
        true  => @options[:label_true]  || "On",
        false => @options[:label_false] || "Off",
      }
    end
  end

  class IntegerItem < SelectItem
    def initialize(*)
      super
      @options[:min] = @options[:min] || 0
      @options[:max] = @options[:max] || 10
      @options[:step] =  @options[:step]  || 1
      cap_value!
    end

    def display_value()
      "#{self.value}"
    end

    def on_left_pressed()
      self.value -= options[:step]
      cap_value!
      @options[:action].call(self) if @options[:action]
    end

    def on_right_pressed()
      self.value += options[:step]
      cap_value!
      @options[:action].call(self) if @options[:action]
    end

    def cap_value!
      self.value = options[:min] if self.value < options[:min]
      self.value = options[:max] if self.value > options[:max]
    end
  end

  class FloatItem < IntegerItem
    def initialize(*)
      super
      @options[:min] = @options[:min] || 0.0
      @options[:max] = @options[:max] || 100.0
      @options[:step] =  @options[:step]  || 1.0
      @options[:round] = @options.key?(:round) ? @options[:round] : 2
      cap_value!
    end

    def display_value()
      value = self.value
      value = value.is_a?(Float) ? sprintf("%.#{@options[:round]}f",value) : value if @options[:round]
      value = 0.0 if value == -0.0
      "#{value}"
    end
  end

  class ListItem < ButtonItem
    def initialize(*)
      super
      @options[:right_action] = lambda{|i|
        UiMenu.show_submenu(:_UiMenuList,{
          values: @options[:collection],
          selected: self.value || 0
        })
      }
      if !UiMenu[:_UiMenuList]
        _UiMenuList = UiMenu.new({
          id: :_UiMenuList
        })
        def _UiMenuList.items
          items = []
          values.each_pair do |key,value|
            items << { type: :button , label: "#{value}" , id: key }
          end
          items
        end
        def _UiMenuList.on_item_select_pressed
          if parent && parent._items[parent.selected]
            parent.values[ parent._items[parent.selected].id ] = @items[@selected].id
          end
          UiMenu.hide_submenu()
        end
        def _UiMenuList.on_nav_back_pressed
          UiMenu.hide_submenu()
        end
      end
    end

  end

  
end
