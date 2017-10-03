
# Runs scripts using Fibers (aka. co-routines)
# Each registered script gets it's body loaded into a Fiber, which
# is called on each `GTAV.tick`. When the script calls `GTAV.wait(ms)`,
# control is yielded back to the runtime with `ms` as the return value.
# The Fiber is then scheduled to run at the requested time in the future,
# and then next Fiber is called. Once all Fibers are called, control is 
# yielded back to the c++ hook and ultimately back to the game

module GTAV

  @@ticks = 0

  @@fibers = {}
  @@fibers_modules = {}
  @@fibers_next_tick_at = {}
  @@fibers_names = nil
  @@current_fiber = nil
  @@current_fiber_name = nil

  @@metrics = nil
  def self.metrics; @@metrics; end

  CALL_LIMIT = 4096

  def self.register(name,enabled = true,&block)
    return if !enabled
    if @@fibers[name]
      log "DID NOT register '#{name}', already loaded", :warn
    else
      log "Registered '#{name}'"
      # @@fibers[name] = Fiber.new(&block)
      @@fibers[name] = Fiber.new {
        @@fibers_modules[name] = Module.new()
        @@fibers_modules[name].instance_eval(&block)
      }
      @@fibers_next_tick_at[name] = 0
      @@metrics.register_fiber(name) if @@metrics
      self.enable_fiber(name,enabled)
    end
  end

  # gets called every engine tick by script.cpp
  def self.tick(*args)
    tick_start = self.time_usec
    begin

      # disable GC during ticks to avoid mid-execution lag
      GC.disable

      # tick each fiber
      self.tick_fibers()

      @@ticks += 1

    rescue => exception
      self.on_error(exception)
    ensure
      # re-enable GC allowing it to run normally
      GC.enable# if @@ticks % 60 == 1
    end
    @@metrics.instrument_tick(time_usec - tick_start) if @@metrics
  end

  def self.tick_fibers
    tick_time = self.time

    @@fibers.each_pair do |name,fiber|

      @@current_fiber = fiber
      @@current_fiber_name = name

      # skip fiber if it's not scheduled to run yet
      next if @@fibers_next_tick_at[name] > tick_time

      begin

        # try to prevent an unyielding fiber from running uncontrollably
        # by setting a quota on how many native functions it can call
        # before it yields. if over the quota, CallLimitExceeded is raised.
        # use GTAV.set_call_limit(-1) to disable the call limit
        GTAV.set_call_limit(CALL_LIMIT)

        # allow fiber to execute until it calls GTAV.wait(ms)
        # the return value of fiber.resume is the ms arg to wait()
        time_start, objs_start = self.time_usec, self.object_count
        wait_ms = fiber.resume
        time_end = self.time_usec

        if wait_ms
          # schedule the fiber's next tick time
          @@fibers_next_tick_at[name] = tick_time + wait_ms
        else
          # fiber dead
        end

        @@metrics.instrument_fiber(name,time_end - time_start, CALL_LIMIT - self.get_call_limit, self.object_count - objs_start) if @@metrics

      rescue => ex

        # if we have to rescue an exception here, it was uncaught inside
        # the fiber. this means there is no valid way to continue execution
        # of the fiber, and we must shut it down
        terminate_fiber(name)
        log "ERROR IN #{name}, shutting down fiber", :error
        on_error(ex)

      end

      @@current_fiber = nil
      @@current_fiber_name = nil

    end
  end

  def self.terminate_current_fiber!
    terminate_fiber(@@current_fiber_name)
  end

  def self.terminate_fiber(name)
    @@fibers_next_tick_at[name] = 999999999
  end

  def self.enable_fiber(name,enable)
    @@fibers_next_tick_at[name] = enable ? 0 : 999999999
  end

  def self.fibers
    @@fibers
  end

  def self.fiber_wait_hash
    ::Hash[ @@fibers.each_pair.map{|k,v| [k,@@fibers_next_tick_at[k]]} ]
  end

  def self.wait(ms)
    if Fiber.current != @@current_fiber
      raise "unregistered fiber called GTAV.wait"
    end
    Fiber.yield(ms)
    nil
  end

  def self.fiber_names
    if !@@fibers_names
      @@fibers_names = @@fibers.keys
    end
    @@fibers_names
  end

  @@_object_count = {}
  def self.object_count
    return 0
    # DO NOT USE: leaks memory like mad
    # ObjectSpace.count_objects(@@_object_count)
    # @@_object_count[:TOTAL] - @@_object_count[:FREE]
  end

  def self.[](key)
    @@fibers_modules[key] || @@nil_proxy
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

end
