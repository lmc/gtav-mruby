
# Runs scripts using Fibers (aka. co-routines)
# Each registered script gets it's body loaded into a Fiber, which
# is called on each `GTAV.tick`. When the script calls `GTAV.wait(ms)`,
# control is yielded back to the runtime with `ms` as the return value.
# The Fiber is then scheduled to run at the requested time in the future,
# and then next Fiber is called. Once all Fibers are called, control is 
# yielded back to the c++ hook and ultimately back to the game


module GTAV
  
  @@ticks = 0

  @@registered_scripts = {}

  @@scripts = []
  @@current_script_idx = nil

  @@metrics = nil
  def self.metrics; @@metrics; end

  # CALL_LIMIT = 4096
  CALL_LIMIT = 32768
  
  @@new_script_id = 0
  def self.register(name, enabled = true, options = {}, &block)
    return self._register(name,&block) if name.is_a?(::Hash)
    return self._register({name: name, enabled: enabled}.merge(options),&block)
  end

  def self._register(options = {},&block)
    options = {
      name:       :"script#{(@@new_script_id += 1).to_s.rjust(5,"0")}",
      start:      true,
      args:       nil,
      enabled:    true,
      register:   true,
      multiple:   false,
      class:      GTAV::Script
    }.merge(options)

    if options[:args]
      options[:start] = true
    end

    return if !options[:enabled]

    if options[:register]
      @@registered_scripts[options[:name]] = [ options , block ]
    end

    if options[:start]
      if options[:register]
        # self.spawn(options[:name])
        self.spawn(options[:name],*Array(options[:args]))
      else
        raise "???"
      end
    end
  end

  def self.spawn(name,*args)
    klass = @@registered_scripts[name][0][:class] || GTAV::Script
    options = @@registered_scripts[name][0].dup
    base_name = options[:name]
    self.metrics.register_fiber(base_name) if @@metrics
    if options[:multiple]
      options[:name] = :"#{base_name}#{(@@new_script_id += 1).to_s.rjust(5,"0")}"
    end
    script = klass.new( options , &@@registered_scripts[name][1] )
    script.start(*args)
    @@scripts << script
    script
  end

  # gets called every engine tick by script.cpp
  def self.tick(*args)
    tick_start = self.time_usec
    begin

      # disable GC during ticks to avoid mid-execution lag
      GC.disable

      # tick each fiber
      self.tick_scripts()

      @@ticks += 1

    rescue => exception
      self.on_error(exception)
    ensure
      # re-enable GC allowing it to run normally
      GC.enable# if @@ticks % 60 == 1
    end
    @@metrics.instrument_tick(time_usec - tick_start) if @@metrics
  end

  def self.script_index(script)
    @@scripts.index(script)
  end

  def self.tick_scripts
    tick_time = self.time

    @@scripts.each_with_index do |script,index|

      @@current_script_idx = index

      # skip fiber if it's not scheduled to run yet
      next if !script.ready?(tick_time)

      begin

        # try to prevent an unyielding fiber from running uncontrollably
        # by setting a quota on how many native functions it can call
        # before it yields. if over the quota, CallLimitExceeded is raised.
        # use GTAV.set_call_limit(-1) to disable the call limit
        GTAV.set_call_limit(CALL_LIMIT)

        # allow fiber to execute until it calls GTAV.wait(ms)
        # the return value of fiber.resume is the ms arg to wait()
        time_start, objs_start = self.time_usec, self.object_count
        wait_ms = script.resume
        time_end = self.time_usec

        if wait_ms
          # schedule the fiber's next tick time
          script.next_tick_at = tick_time + wait_ms
        else
          # fiber dead
        end

        @@metrics.instrument_fiber(script.script_name,time_end - time_start, CALL_LIMIT - self.get_call_limit, self.object_count - objs_start) if @@metrics

      rescue => ex

        # if we have to rescue an exception here, it was uncaught inside
        # the fiber. this means there is no valid way to continue execution
        # of the fiber, and we must shut it down
        terminate_script_idx(index)
        log "ERROR IN idx #{index} `#{script.script_name}`, shutting down script", :error, :fiber, :script_name, script.script_name, :script_index, index
        on_error(ex)

      end

      @@current_script_idx = nil

    end
  end

  def self.terminate_current_script!
    self.terminate_script_idx(@@current_script_idx)
  end
  def self.terminate_current_fiber!; self.terminate_current_script!; end

  def self.delete_script_idx(idx)
    @@scripts.delete(idx)
  end

  def self.terminate_script_idx(idx)
    @@scripts[idx]&.next_tick_at = 999999999
  end

  def self.enable_script(idx,enable)
    @@scripts[idx]&.next_tick_at = enable ? 0 : 999999999
  end

  def self.fibers
    @@scripts
  end

  def self.registered_scripts
    @@registered_scripts
  end

  def self.fiber_wait_hash
    ::Hash[ @@scripts.each.map{|v| [v.script_name,v.next_tick_at[k]]} ]
  end

  def self.wait(ms)
    if Fiber.current != @@scripts[@@current_script_idx]&.fiber
      raise "unregistered fiber called GTAV.wait"
    end
    Fiber.yield(ms)
    nil
  end

  def self.fiber_names
    @@scripts.map(&:script_name)
  end

  @@_object_count = {}
  def self.object_count
    return 0
    # DO NOT USE: leaks memory like mad
    # ObjectSpace.count_objects(@@_object_count)
    # @@_object_count[:TOTAL] - @@_object_count[:FREE]
  end

  def self.[](key)
    self.script_by_name(key)&.module || @@nil_proxy
  end

  def self.script_by_name(name)
    @@scripts.detect{|s| s.script_name == name}
  end
  
  class NilProxy
    def method_missing(*)
      self
    end
    def nil?
      true
    end
  end
  @@nil_proxy = NilProxy.new
  

  # @@load_script_as_proc = false
  # @@load_script_procs = []
  # def self.load_script(filename)
  #   begin
  #     if @@load_script_as_proc
  #       @@load_script_procs << GTAV.load_script_as_proc(filename)
  #     else
  #       GTAV.load(filename)
  #     end
  #   rescue => ex
  #     on_error(ex)
  #   end
  # end
  
  # @@code_start = "proc { "
  # @@code_end = " }"
  # def self.load_script_as_proc(filename)
  #   return nil if !File.exist?(filename)
  #   code = @@code_start
  #   code += File.read(filename)
  #   code += @@code_end
  #   return nil if !GTAV.is_syntax_valid?(code)
  #   eval(code)
  # end

  # def self.load_scripts()
  #   begin
  #     @@load_script_as_proc = true
  #     @@load_script_procs = []
  #     GTAV.load_dir('.\mruby\scripts','*.rb')
  #     log "got #{@@load_script_procs.size} script procs"
  #     @@load_script_procs.each do |script_proc|
        
  #     end
  #   ensure
  #     @@load_script_as_proc = false
  #   end
  # end


end
