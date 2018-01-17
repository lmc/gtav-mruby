
module GUI

  class Notification
    def initialize(text)
      @text = text
      @handle = nil
    end

    def handle
      @handle
    end
    
    def draw()
      UI::_SET_NOTIFICATION_TEXT_ENTRY("STRING")
      UI::_ADD_TEXT_COMPONENT_STRING(@text)
      @handle = UI::_DRAW_NOTIFICATION(blink = false, false)
    end

    def remove
      if @handle
        UI::_REMOVE_NOTIFICATION(@handle)
        @handle = nil
      end
    end
  end

  class InstructionalButtons
    
    # GAME BUG: label text is not drawn with ARROW_UP
    BUTTONS = [
      :ARROW_UP,
      :ARROW_DOWN,
      :ARROW_LEFT,
      :ARROW_RIGHT,
      :DPAD_UP,
      :DPAD_DOWN,
      :DPAD_LEFT,
      :DPAD_RIGHT,
      :DPAD_BLANK,
      :DPAD_ALL,
      :DPAD_UP_DOWN,
      :DPAD_LEFT_RIGHT,
      :LSTICK_UP,
      :LSTICK_DOWN,
      :LSTICK_LEFT,
      :LSTICK_RIGHT,
      :LSTICK,
      :LSTICK_ALL,
      :LSTICK_UP_DOWN,
      :LSTICK_LEFT_RIGHT,
      :LSTICK_ROTATE,
      :RSTICK_UP,
      :RSTICK_DOWN,
      :RSTICK_LEFT,
      :RSTICK_RIGHT,
      :RSTICK,
      :RSTICK_ALL,
      :RSTICK_UP_DOWN,
      :RSTICK_LEFT_RIGHT,
      :RSTICK_ROTATE,
      :A,
      :B,
      :X,
      :Y,
      :LB,
      :LT,
      :RB,
      :RT,
      :START,
      :SELECT,
      :RED_BOX,
      :RED_BOX_1,
      :RED_BOX_2,
      :RED_BOX_3,
      :LOADING_LEFT,
      :ARROW_UP_DOWN,
      :ARROW_LEFT_RIGHT,
      :ARROW_ALL,
      :LOADING_LEFT_2,
      :SAVE_LEFT,
      :LOADING_RIGHT,
    ]

    def initialize
      @items = []
    end

    def add(label, options = {})
      if options[:button]
        @items << [label,options[:button]]
      elsif options[:key]
        @items << [label,nil,options[:key]]
      elsif options[:input]
        input = CONTROLS::_GET_CONTROL_ACTION_NAME(0,options[:input],true)
        @items << [label,nil,nil,input]
      end
    end

    def draw(scaleform)
      GRAPHICS::DRAW_SCALEFORM_MOVIE_FULLSCREEN(scaleform, 255, 255, 255, 0, 0)
      GRAPHICS::_PUSH_SCALEFORM_MOVIE_FUNCTION(scaleform,"CLEAR_ALL")
      GRAPHICS::_POP_SCALEFORM_MOVIE_FUNCTION_VOID()
      GRAPHICS::_PUSH_SCALEFORM_MOVIE_FUNCTION(scaleform,"SET_CLEAR_SPACE")
      GRAPHICS::_PUSH_SCALEFORM_MOVIE_FUNCTION_PARAMETER_INT(1200)
      GRAPHICS::_POP_SCALEFORM_MOVIE_FUNCTION_VOID()

      items = @items
      items = [["none"]] if items.size == 0

      items.reverse.each_with_index do |item,index|
        GRAPHICS::_PUSH_SCALEFORM_MOVIE_FUNCTION(scaleform,"SET_DATA_SLOT")
        GRAPHICS::_PUSH_SCALEFORM_MOVIE_FUNCTION_PARAMETER_INT(index)

        if item[1]
          GRAPHICS::_PUSH_SCALEFORM_MOVIE_FUNCTION_PARAMETER_INT(BUTTONS.index(item[1]) || item[1])
        elsif item[2]
          GRAPHICS::_BEGIN_TEXT_COMPONENT("STRING")
          UI::_ADD_TEXT_COMPONENT_STRING("t_#{item[2].upcase}")
          GRAPHICS::_END_TEXT_COMPONENT()
        elsif item[3]
          GRAPHICS::_0xE83A3E3557A56640(item[3])
        else
          GRAPHICS::_PUSH_SCALEFORM_MOVIE_FUNCTION_PARAMETER_INT(-1)
        end

        GRAPHICS::_BEGIN_TEXT_COMPONENT("STRING")
        UI::_ADD_TEXT_COMPONENT_STRING("#{item[0]}")
        GRAPHICS::_END_TEXT_COMPONENT()

        GRAPHICS::_POP_SCALEFORM_MOVIE_FUNCTION_VOID()
      end

      GRAPHICS::_PUSH_SCALEFORM_MOVIE_FUNCTION(scaleform,"SET_BACKGROUND_COLOUR")
      GRAPHICS::_PUSH_SCALEFORM_MOVIE_FUNCTION_PARAMETER_INT(0)
      GRAPHICS::_PUSH_SCALEFORM_MOVIE_FUNCTION_PARAMETER_INT(0)
      GRAPHICS::_PUSH_SCALEFORM_MOVIE_FUNCTION_PARAMETER_INT(0)
      GRAPHICS::_PUSH_SCALEFORM_MOVIE_FUNCTION_PARAMETER_INT(80)
      GRAPHICS::_POP_SCALEFORM_MOVIE_FUNCTION_VOID()


      GRAPHICS::_PUSH_SCALEFORM_MOVIE_FUNCTION(scaleform,"DRAW_INSTRUCTIONAL_BUTTONS")
      GRAPHICS::_POP_SCALEFORM_MOVIE_FUNCTION_VOID()
    end
  end

end
