
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
  @@fibers_next_tick_at = {}
  @@fibers_names = nil
  @@current_fiber = nil

  @@metrics = nil
  def self.metrics; @@metrics; end

  CALL_LIMIT = 4096

  def self.register(name,enabled = true,&block)
    return if !enabled
    log "Registered '#{name}'"
    @@fibers[name] = Fiber.new(&block)
    @@fibers_next_tick_at[name] = 0
    @@metrics.register_fiber(name) if @@metrics
  end

  # gets called every engine tick by script.cpp
  def self.tick(*args)
    begin
      tick_start = self.time_usec

      # disable GC during ticks to avoid mid-execution lag
      GC.disable

      # tick each fiber
      self.tick_fibers()

      @@ticks += 1

      @@metrics.instrument_tick(time_usec - tick_start) if @@metrics
    rescue => exception
      self.on_error(exception)
    ensure
      # re-enable GC allowing it to run normally
      GC.enable
    end
  end

  def self.tick_fibers
    tick_time = self.time

    @@fibers.each_pair do |name,fiber|

      @@current_fiber = fiber

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
        fiber_start = self.time_usec
        wait_ms = fiber.resume
        fiber_end = self.time_usec

        if wait_ms
          # schedule the fiber's next tick time
          @@fibers_next_tick_at[name] = tick_time + wait_ms
        else
          # fiber dead
        end

        @@metrics.instrument_fiber(name,fiber_end - fiber_start, CALL_LIMIT - GTAV.get_call_limit) if @@metrics

      rescue => ex

        # if we have to rescue an exception here, it was uncaught inside
        # the fiber. this means there is no valid way to continue execution
        # of the fiber, and we must shut it down
        @@fibers.delete(name)
        log "ERROR IN #{name}, shutting down fiber", :error
        on_error(ex)

      end

    end
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

end
