module GTAV
  class Script

    def self.inherited(klass)
      klass.register!
    end

    def self.register!(&block)
      block ||= lambda{ tick }
      GTAV.register({
        name: self.to_s.to_sym,
        start: false,
        class: self,
        register: true
      },&block)
    end

    attr_accessor :script_name
    attr_accessor :options
    attr_accessor :module
    attr_accessor :fiber
    attr_accessor :next_tick_at
    attr_accessor :block

    def initialize(options = {}, &block)
      @options = {name: :noname}.merge(options)
      @script_name = options.delete(:name)
      @block = block
    end

    def start(*args)
      @next_tick_at = 0
      @module = self
      block = @block
      @fiber = Fiber.new do
        if block.arity == args.size && block.arity != 0
          @module.instance_exec(*args,&block)
        else
          @module.instance_eval(&block)
        end
      end
    end

    def ready?(now)
      @fiber.alive? && @next_tick_at < now
    end

    def alive?
      @fiber.alive? && @next_tick_at < 999999999
    end

    def suspended?
      @fiber.alive? && @next_tick_at >= 999999999
    end

    def resume
      @fiber.resume
    end

    def terminate!
      GTAV.terminate_script_idx(self.script_index)
    end

    def script_index
      GTAV.script_index(self)
    end
  end
end