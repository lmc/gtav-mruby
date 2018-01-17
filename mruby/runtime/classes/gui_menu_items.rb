
class GUI::Menu

  class Item
    def initialize(menu,options)
      @menu = menu
      @options = options
      @enabled = true
      self.value = option_value(:default) if @options.key?(:default) && self.value.nil?
      self.value = @options[:value]       if @options.key?(:value)

      # events:
      # change    - [inputs] - value changes
      # action    - [all] - A button pressed (ignored for checkbox/list/colour)
      # secondary - [all] - X button pressed
      # tertiary  - [all] - Y button pressed
      # expand    - [button] - dpad-right pressed, shows right-arrow on button

      @options[:change]         = @options.key?(:change)         ? @options[:change]         : nil
      @options[:change_name]    = @options.key?(:change_name)    ? @options[:change_name]    : "Change"

      @options[:action]         = @options.key?(:action)         ? @options[:action]         : nil
      @options[:action_name]    = @options.key?(:action_name)    ? @options[:action_name]    : "Select"
      
      @options[:expand]         = @options.key?(:expand)         ? @options[:expand]         : nil
      @options[:expand_name]    = @options.key?(:expand_name)    ? @options[:expand_name]    : "Expand"
      @options[:expand_visible] = @options.key?(:expand_visible) ? @options[:expand_visible] : true

      @options[:secondary]      = @options.key?(:secondary)      ? @options[:secondary]      : nil
      @options[:secondary_name] = @options.key?(:secondary_name) ? @options[:secondary_name] : "Secondary"

      @options[:tertiary]       = @options.key?(:tertiary)       ? @options[:tertiary]       : nil
      @options[:tertiary_name]  = @options.key?(:tertiary_name)  ? @options[:tertiary_name]  : "Tertiary"

      update
    end

    def draw(x,y,w,selected)
      h = 0.0345
      px = 0.0044
      py = 0.004

      if selected
        GRAPHICS::DRAW_RECT(x + (w / 2), y + (h / 2), w, h, 240,240,240,255)
      else
        GRAPHICS::DRAW_RECT(x + (w / 2), y + (h / 2), w, h, 0,0,0,127)
      end

      draw_custom(content(selected,enabled?), x, px, y, py, w, selected, enabled?)

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

    def content(selected,enabled)
      [[:text,"default content"]]
    end

    def draw_custom(calls, x, px, y, py, w, selected, enabled)
      wx = x + px
      wy = y + py
      state = :left
      calls.each do |call|
        call[1] ||= nil
        call[2] ||= {}
        cselected = selected
        cselected = !cselected if call[0] == :badge
        colour = cselected ? :colour_item_selected_text : :colour_item_text
        if !enabled
          colour = cselected ? :colour_item_disabled_selected_text : :colour_item_disabled_text
        end
        ww = case call[0]
        when :text, :cell, :badge
          text = call[2][:text].is_a?(GUI::Text) ? call[2][:text] : GUI::Menu.theme( call[2][:text] || :text_item )
          value = call[1]
          text.rgba = GUI::Menu.theme(colour)
          text.alignment = state == :left ? 1 : 2# if [:text,:badge].include?(call[0])
          px1 = x + px
          px2 = state == :left ? (x + w) - px : wx
          tw = text.width(value, wx, wy, px1, px2)
          if call[0] == :badge
            badge_bg = call[2][:badge_bg] || RGBA(32,220,32,240)
            h = 0.0345
            bw = tw
            bw += 0.00225
            bh = h * 0.8
            bx = wx
            bx -= tw - 0.0005 if state == :right
            bx += (tw / 2)
            GRAPHICS::DRAW_RECT(bx , y + (bh / 8) + (bh / 2), bw, bh, *badge_bg)
          end
          text.draw(value, wx, wy, px1, px2)
          if call[2][:w]
            call[2][:w] * w
          elsif call[0] == :badge
            bw + 0.002
          else
            tw
          end
        when :arrow, :arrow_selected
          if call[0] == :arrow || (selected && enabled)
            char = {:left => "1", :right => "2"}[call[1]] || "1"
            colour = selected ? :colour_item_selected_text : :colour_item_text
            GUI::Menu.theme(:text_icons).rgba = GUI::Menu.theme(colour)
            GUI::Menu.theme(:text_icons).draw(char, wx - 0.005, wy)
            0.01
          else
            0.0
          end
        when :sprite
          sw = 0.02
          sh = 0.02
          sx = 0.005
          sy = 0.014
          sx *= -1 if state == :right
          GRAPHICS::DRAW_SPRITE(*call[1],wx+sx,wy+sy,sw,sh*srd,0.0,255,255,255,255)
          sw / 2.0
        when :right
          state = :right
          wx = x + w - px
          0  
        end
        # ww *= -1.0 if state == :right
        if state == :left
          wx += ww
        else
          wx -= ww
        end
      end
    end

    def instructional_buttons
      
    end

    def srd
      @srd ||= begin
        w,h = GRAPHICS::GET_SCREEN_RESOLUTION()
        w.to_f/h.to_f
      end
    end
  end
  

  class HeaderItem < Item
    def initialize(*)
      super
      @options[:title] = @options[:label] if @options.key?(:label)

      @options[:title] = @options.key?(:title) ? @options[:title] : "Header"
      @options[:title_style] = @options[:title_style] || GUI::Text.new(font: 1, scale2: 1.1, alignment: 0)
      @options[:title_bg] = @options.key?(:title_bg) ? @options[:title_bg] : RGBA(15,110,184,255)
      @options[:subtitle] = @options.key?(:subtitle) ? @options[:subtitle] : ""
      @options[:subtitle_style] = @options[:subtitle_style] || GUI::Text.new(font: 0, scale2: 0.325, alignment: 1)
      @options[:subtitle_bg] = @options.key?(:subtitle_bg) ? @options[:title_bg] : RGBA(0,0,0,255)
      @options[:counter] = @options.key?(:counter) ? @options[:counter] : true
      @options[:counter_style] = @options[:counter_style] || GUI::Text.new(font: 0, scale2: 0.325, alignment: 3)
    end
    def draw(x,y,w,selected)
      h = 0.101
      wx = x
      wy = y
      px = 0.0125
      py = 0.02
      if @options[:title_bg] && @options[:title]
        GRAPHICS::DRAW_RECT(wx + (w / 2), wy + (h / 2), w, h, *option_value(:title_bg))
      end
      if @options[:title]
        text = option_value(:title)
        @options[:title_style].draw(text, wx + px + ((w - (px * 2)) / 2), wy + py, wx + px, (wx + w) - px)
      end
      if @options[:subtitle]
        oh = @options[:title] ? h : 0.0
        wy += oh
        h = 0.0345
        px = 0.0044
        py = 0.004
        if @options[:subtitle_bg]
          GRAPHICS::DRAW_RECT(wx + (w / 2), wy + (h / 2), w, h, *@options[:subtitle_bg])
        end
        if @options[:subtitle]
          text = option_value(:subtitle)
          if text.is_a?(Array)
            draw_custom(text, wx, px, wy, py, w, selected, enabled?)
          else
            @options[:subtitle_style].draw(text, wx + px, wy + py)
          end
        end
        if @options[:counter]
          @options[:counter_style].draw("#{@menu.selected} / #{@menu.item_count}", (wx + (w/2)) - px, wy + py, wx + px, (wx + w) - px)
        end
        return oh + h
      end
      return h
    end
  end

  class HelpItem < Item
    def initialize(*)
      super
      @options[:text] = @options[:text] || GUI::Text.new(font: 0, scale2: 0.325)
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
      if @menu.selected
        update_help(@menu.instance_eval("@items")[@menu.selected])
      end
    end

    def update_help(item)
      @value = item&.option_value(:help) || option_value(:default) || ""
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
      @options[:text] = @options[:text] || GUI::Text.new(font: 0, scale2: 0.325)
      @options[:label] = @options[:label] || "Button"
      @value = option_value(:value,nil)
      @options[:expand] ||= @options.delete(:right_action)
    end

    def content(selected,enabled)
      label = option_value(:label)
      return label if label.is_a?(Array)
      content = []
      content << [:text,label]
      if @options[:expand] && (selected || option_value(:expand_visible) == true)
        content << [:right]
        content << [:arrow,:right]
      end
      content
    end

    def on_select_pressed()
      return if !@enabled
      if @options[:expand] && !@options[:action]
        @options[:expand].call(self)
      else
        @options[:action].call(self) if @options[:action]
      end
      nil
    end

    def on_right_pressed
      return if !@enabled
      @options[:expand].call(self) if @options[:expand]
      nil
    end

    def instructional_buttons
      helper = GUI::InstructionalButtons.new
      helper.add("Up/Down",button: :DPAD_UP_DOWN)
      if @options[:expand] && !@options[:action]
        helper.add(option_value(:expand_name),input: Control::PhoneSelect)
      else
        action_name = option_value(:action_name)
        helper.add(option_value(:expand_name),button: :DPAD_RIGHT) if @options[:expand]
        helper.add(option_value(:secondary_name),input: Control::PhoneExtraOption) if @options[:secondary]
        helper.add(option_value(:tertiary_name),input: Control::PhoneOption) if @options[:tertiary]
        helper.add(action_name,input: Control::PhoneSelect) if action_name
      end
      helper.add("Cancel",input: Control::PhoneCancel)
      helper
    end

  end

  # Rockstar's original select items behave like:
  # By default: no action when A is pressed, help is "Change setting dpad-left-right"
  # 
  class SelectItem < Item
    def initialize(*)
      super
      @options[:text_label] = @options[:text_label] || GUI::Text.new(font: 0, scale2: 0.325)
      # @options[:text_value] = @options[:text_value] || GUI::Text.new(font: 2, scale2: 0.3, alignment: 3)
      @options[:text_value] = @options[:text_value] || GUI::Text.new(font: 0, scale2: 0.325, alignment: 3)
      @options[:label] = @options[:label] || "Button"
      @options[:collection] = @options[:collection] || {0=>"0",1=>"1"}

      # @options[:change] ||= @options[:action]
      # @options[:change_name] ||= @options[:select_label]
      # @options[:action] ||= @options[:select_action]
      # @options[:action_name] ||= @options[:select_action_label]
    end

    def content(selected,enabled)
      label = option_value(:label)
      return label if label.is_a?(Array)
      content = []
      content << [:text,label]
      content << [:right]
      content << [:arrow_selected,:right]
      content << [:text,display_value]
      content << [:arrow_selected,:left]
      content
    end

    def display_value()
      "#{@options[:collection][self.value] || self.value.inspect}"
    end

    def on_select_pressed()
      @options[:action].call(self) if @options[:action]
    end

    def on_left_pressed()
      return if !@enabled
      index = @options[:collection].keys.index(value)
      if !@options[:collection].keys[index - 1].nil?
        self.value = @options[:collection].keys[index - 1]
        @options[:change].call(self) if @options[:change]
      end
    end

    def on_right_pressed()
      return if !@enabled
      index = @options[:collection].keys.index(value)
      if !@options[:collection].keys[index + 1].nil?
        self.value = @options[:collection].keys[index + 1]
      else
        self.value = @options[:collection].keys[0]
      end
      @options[:change].call(self) if @options[:change]
    end

    def instructional_buttons
      helper = GUI::InstructionalButtons.new
      helper.add("Up/Down",button: :DPAD_UP_DOWN)
      helper.add(option_value(:change_name),button: :DPAD_LEFT_RIGHT)
      helper.add(option_value(:action_name),input: Control::PhoneSelect) if @options[:action]
      helper.add("Cancel",input: Control::PhoneCancel)
      helper
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

    def content(selected,enabled)
      items = []
      items << [:text,option_value(:label)]
      items << [:right]
      if @options[:right_action] && (selected || option_value(:right_action_show))
        items << [:arrow,:right]
      end
      if self.value
        if selected
          items << [:sprite,["CommonMenu","Shop_Box_TickB"]]
        else
          items << [:sprite,["CommonMenu","Shop_Box_Tick"]]
        end
      else
        if selected
          items << [:sprite,["CommonMenu","Shop_Box_BlankB"]]
        else
          items << [:sprite,["CommonMenu","Shop_Box_Blank"]]
        end
      end
      items
    end

    def on_select_pressed()
      self.value = !self.value
      @options[:change].call(self) if @options[:change]
    end

    def on_left_pressed()
      # do nothing
    end

    def on_right_pressed()
      # do nothing
    end

    def instructional_buttons
      helper = GUI::InstructionalButtons.new
      helper.add("Up/Down",button: :DPAD_UP_DOWN)
      helper.add(option_value(:change_name),input: Control::PhoneSelect)
      helper.add("Cancel",input: Control::PhoneCancel)
      helper
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
      @options[:change].call(self) if @options[:change]
    end

    def on_right_pressed()
      self.value += options[:step]
      cap_value!
      @options[:change].call(self) if @options[:change]
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
      @options[:expand_visible] = :hover
      @options[:expand] = lambda{|i|
        GUI::Menu.show_submenu(:_GuiMenuList,{
          values: @options[:collection],
          selected: self.value || 0
        })
      }
      if !GUI::Menu[:_GuiMenuList]
        _GuiMenuList = GUI::Menu.new({
          id: :_GuiMenuList
        })
        def _GuiMenuList.items
          items = []
          values.each_pair do |key,value|
            items << { type: :button , label: "#{value}" , id: key }
          end
          items
        end
        def _GuiMenuList.on_item_select_pressed
          if parent && parent._items[parent.selected]
            parent.values[ parent._items[parent.selected].id ] = @items[@selected].id
            parent._items[parent.selected].option_value(:change) # invoke change callback
          end
          GUI::Menu.hide_submenu()
        end
        def _GuiMenuList.on_nav_back_pressed
          GUI::Menu.hide_submenu()
        end
      end
    end
    def content(selected,enabled)
      label = option_value(:label)
      return label if label.is_a?(Array)
      content = []
      content << [:text,label]
      if @options[:expand] && (selected || option_value(:expand_visible))
        content << [:right]
        content << [:arrow,:right]
        content << [:text,display_value]
      end
      content
    end
    def display_value
      "#{@options[:collection][value] || value.inspect}"
    end
  end

  class ColourItem < ButtonItem
    def initialize(*)
      super
      @options[:expand_visible] = true
      @options[:expand] = lambda{|i|
        GUI::Menu.show_submenu(:_GuiMenuColour,{
          values: { r: self.value.r, g: self.value.g, b: self.value.b, a: self.value.a, id: i.id },
          selected: 0
        })
      }
      if !GUI::Menu[:_GuiMenuColour]
        _GuiMenuColour = GUI::Menu.new({ id: :_GuiMenuColour , w: 0.2 })
        def _GuiMenuColour.items
          items = []
          items << { type: :header , label: "", title_bg: ->(i){ v = i.menu.values; RGBA(v[:r],v[:g],v[:b],v[:a]) } }
          items << { type: :integer , label: "Red"   , id: :r , min: 0 , max: 255 }
          items << { type: :integer , label: "Green" , id: :g , min: 0 , max: 255 }
          items << { type: :integer , label: "Blue"  , id: :b , min: 0 , max: 255 }
          items << { type: :integer , label: "Alpha" , id: :a , min: 0 , max: 255 }
          items << { type: :help , default: ->(i){ i.menu.values.inspect } }
          items
        end
        def _GuiMenuColour.defaults(values = {})
          { r: 100 , g: 200 , b: 255 , a: 255 }
        end
        def _GuiMenuColour.on_item_left_pressed
          super
          sync_value
        end
        def _GuiMenuColour.on_item_right_pressed
          super
          sync_value
        end
        def _GuiMenuColour.sync_value
          value = self.values
          if parent && parent._items[parent.selected]
            parent.values[value[:id]] = RGBA(*value.values_at(:r,:g,:b,:a))
            parent._items[parent.selected].option_value(:change) # invoke change callback
          end
        end
        def _GuiMenuColour.on_nav_back_pressed
          GUI::Menu.hide_submenu()
        end
      end
    end
    
    def content(selected,enabled)
      contents = super
      contents << [:badge,"rgba",{badge_bg: self.value}]
      contents
    end
  end

  
end
