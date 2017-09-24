
module GTAV::Metrics

  @@metrics = {}
  @@do_metrics = false
  INSTRUMENTATION_QUEUE_TICKS_SIZE = 60
  INSTRUMENTATION_QUEUE_SIZE = 20

  def self.register_fiber(name)
    self.metric_register("fiber.#{name}.tick_times",INSTRUMENTATION_QUEUE_SIZE)
    self.metric_register("fiber.#{name}.calls",INSTRUMENTATION_QUEUE_SIZE)
    self.metric_register("fiber.#{name}.objects",INSTRUMENTATION_QUEUE_SIZE)
  end

  def self.metric_register(name,size)
    @@metrics[name] = Queue.new(size)
  end

  def self.metric(name)
    @@metrics[name]
  end
  class << self
    alias [] metric
  end

  def self.instrument_tick(tick_time)
    @@metrics["runtime.tick_times"] << tick_time
  end

  def self.instrument_fiber(name,time,calls,objects)
    self.metric("fiber.#{name}.tick_times") << time
    self.metric("fiber.#{name}.calls") << calls
    self.metric("fiber.#{name}.objects") << objects
  end

  self.metric_register("runtime.tick_times",INSTRUMENTATION_QUEUE_TICKS_SIZE)

end

module GTAV
  @@metrics = GTAV::Metrics
end
