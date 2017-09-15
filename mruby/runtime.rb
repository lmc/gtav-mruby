
class Queue
  def initialize(max_size)
    @max_size = max_size
    @array = []
  end
  def <<(val)
    @array.shift if @array.size >= @max_size
    @array.push(val)
  end
  def to_a
    @array.to_a
  end
end

module GTAV

  @@ticks = 0
  @@boot_time = Time.now.to_i
  @@state = nil
  @@fibers = {}
  @@fibers_next_tick_at = {}

  CALL_LIMIT = 4096
  @@do_metrics = false
  INSTRUMENTATION_QUEUE_SIZE = 20
  @@counters_tick_times = Queue.new(INSTRUMENTATION_QUEUE_SIZE)
  @@counters_fiber_tick_times = {}
  @@counters_fiber_calls = {}

  def self.register(name,&block)
    puts "register #{name}"
    @@fibers[name] = Fiber.new(&block)
    @@fibers_next_tick_at[name] = 0
    @@counters_fiber_tick_times[name] = Queue.new(INSTRUMENTATION_QUEUE_SIZE)
    @@counters_fiber_calls[name] = Queue.new(INSTRUMENTATION_QUEUE_SIZE)
  end
  
  # gets called every engine tick by script.cpp
  def self.tick(*args)
    begin
      @@do_metrics = @@ticks % 10 == 0
      start = self.time_usec
      GC.disable
      self.reload! if GTAV.is_key_just_up(0x7A) # F11
      self.tick_fibers()
      tick_time = self.time_usec - start
      @@counters_tick_times << tick_time if @@do_metrics
      puts "SLOW TICK (#{tick_time})" if tick_time > 0.005 # 5 ms
    rescue => exception
      self.on_error(exception)
    ensure
      GC.enable
      @@ticks += 1
    end
  end

  def self.tick_fibers
    tick_time = self.time

    @@fibers.each_pair do |name,fiber|

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
        
        if @@do_metrics
          @@counters_fiber_tick_times[name] << (fiber_end - fiber_start)
          @@counters_fiber_calls[name] << (CALL_LIMIT - GTAV.get_call_limit)
        end

        # schedule the fiber's next tick time
        @@fibers_next_tick_at[name] = tick_time + wait_ms

      rescue => ex

        # if we have to rescue an exception here, it was uncaught inside
        # the fiber. this means there is no valid way to continue execution
        # of the fiber, and we must shut it down
        @@fibers.delete(name)
        puts "ERROR IN #{name}, shutting down fiber"
        on_error(ex)

      end

    end
  end

  def self.wait(ms)
    Fiber.yield(ms)
    nil
  end

  def self.reload!
    puts "GTAV.reload!"
    @@state = :reloading
    @@filenames.each_pair do |filename,_|
      GTAV.load_script(filename)
    end
  ensure
    @@state = nil
    puts "GTAV.reload! complete"
  end

  def self.reloading?
    @@state == :reloading
  end

  def self.time
    time = Time.now
    sec,usec = time.to_i, time.usec
    sec -= @@boot_time if @@boot_time
    (sec.to_i * 1000) + (usec / 1000).to_i
  end

  def self.time_usec
    time = Time.now
    sec,usec = time.to_i, time.usec
    sec -= @@boot_time if @@boot_time
    sec.to_f + (usec.to_f / 1000000.0)
  end

  def self.counters_tick_times
    @@counters_tick_times.to_a
  end

  def self.counters_fiber_tick_times
    @@counters_fiber_tick_times
  end
  def self.counters_fiber_calls
    @@counters_fiber_calls
  end

end
