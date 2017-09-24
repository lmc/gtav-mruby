# draws performance metrics onscreen
# has a tick time chart, log viewer and a table of tick times/call counts per-fiber

GTAV.register(:DebugMetrics) do

  @has_metrics = !!GTAV.metrics
  @has_logger = GTAV.respond_to?(:logger_buffer)
  raise "No runtime metrics available (load runtime/runtime_metrics.rb)" if !@has_metrics

  DISPLAY_MODES = [:none,:time,:calls,:all]
  DISPLAY_WIDTHS = {
    :none => [0.2,[1.0]],
    :time => [0.2,[0.5,0.25,0.25]],
    :calls => [0.2,[0.5,0.25,0.25]],
    :all => [0.3,[0.4,0.15,0.15,0.15,0.15]],
  }
  @mode = :time

  TICK_CHART = UiBarChart.new(x: 1.0 - 0.2 - 0.012, y: 0.01, w: 0.2, h: 0.09, limits: [0.0,0.005])

  METRICS_HEADER_TEXT_STYLE = UiStyledText.new(font: 4, scale2: 0.42)
  METRICS_VALUE_TEXT_STYLE = UiStyledText.new(font: 5, scale2: 0.42, proportional: false)
  METRICS_TABLE = UiTable.new(
    x: 1.0 - 0.2 - 0.015,
    y: 0.25,
    w: 0.2,
    # h: 0.25,
    rh: 0.03,
    widths: [0.5,0.25,0.25],
    p: 0.005,
    pco: 0.005,
    pci: 0.005,
    pro: 0.005,
    header_row_text: METRICS_HEADER_TEXT_STYLE,
    body_row_text: METRICS_VALUE_TEXT_STYLE,
  )

  def METRICS_TABLE.text_class_for(ri,ci)
    if ri == 0 || ci == 0
      METRICS_HEADER_TEXT_STYLE
    else
      METRICS_VALUE_TEXT_STYLE
    end
  end

  LOGGER_TEXT_STYLE = UiStyledText.new(font: 0, scale2: 0.3)
  LOGGER_TABLE = UiTable.new(
    x: 1.0 - 0.2 - 0.015,
    y: 0.12,
    w: 0.2,
    # h: 0.25,
    rh: 0.02,
    p: 0.005,
    pco: 0.005,
    pci: 0.005,
    # pro: 0.005,
    pro: 0.001,
    pri: -0.002,
    cell_text: LOGGER_TEXT_STYLE
  )


  def avg(array,default = 0.0)
    num = 0
    array.each{|i| num += i}
    num /= array.size
    num = 0.0 if num.nan?
    num
  end
  def max(array,default = 0.0)
    m = 0
    array.each{|i| m = i if i > m}
    m
  end


  @data_update_idx = 0
  def update_data_once!
    _update_data!(@data_update_idx)
    @data_update_idx += 1
    if @data_update_idx >= METRICS_TABLE.data.size - 2
      update_totals!
      @data_update_idx = 0
    end
  end

  def update_all_data!
    METRICS_TABLE.data = [[]]
    METRICS_TABLE.data[0] = ["Fiber Name"]
    METRICS_TABLE.data[0] += ["Avg. Time","Max Time"] if [:time,:all].include?(@mode)
    METRICS_TABLE.data[0] += ["Avg. Calls","Max Calls"] if [:calls,:all].include?(@mode)
    GTAV.fiber_names.each_with_index do |name,i|
      METRICS_TABLE.data[i + 1] = []
      update_data_once!
    end
    METRICS_TABLE.data << []
    update_totals!
  end

  def _update_data!(idx)
    name = GTAV.fiber_names[idx]
    total_last_calls = -1

    row = []
    row << "#{idx}: #{name.to_s}"
    if [:time,:all].include?(@mode)
      tick_times = GTAV.metrics["fiber.#{name}.tick_times"].to_a
      row << "#{sprintf("%.3f",avg(tick_times,0.0) * 1000.0)}ms"
      row << "#{sprintf("%.3f",max(tick_times,0.0) * 1000.0)}ms"
    end
    if [:calls,:all].include?(@mode)
      calls = GTAV.metrics["fiber.#{name}.calls"].to_a
      row << avg(calls).to_i.to_s
      row << max(calls).to_s
    end

    # + 1 for header row
    METRICS_TABLE.data[idx + 1] = row
  end

  def update_totals!
    total_last_calls = -1
    times = GTAV.metrics["runtime.tick_times"].to_a
    METRICS_TABLE.data[-1] = ["GTAV.tick Total"]
    if [:time,:all].include?(@mode)
      METRICS_TABLE.data[-1] += [
        "#{sprintf("%.3f",avg(times,0.0) * 1000.0)}ms",
        "#{sprintf("%.3f",max(times,0.0) * 1000.0)}ms",
      ]
    end
    if [:calls,:all].include?(@mode)
      METRICS_TABLE.data[-1] += [
        "-",
        "-",
      ]
    end
  end

  def draw_tick_chart!
    TICK_CHART.data = GTAV.metrics["runtime.tick_times"].to_a
    TICK_CHART.draw
  end

  def draw_table!
    METRICS_TABLE.draw
  end

  def draw_logger!
    LOGGER_TABLE.data = GTAV.logger_buffer.to_a.last(5).map{|b| [b]}
    LOGGER_TABLE.draw
  end

  update_all_data!

  loop do
    if GTAV.is_key_just_up(0x79) # F10
      mindex = DISPLAY_MODES.index(@mode) + 1
      mindex = 0 if mindex >= DISPLAY_MODES.size
      @mode = DISPLAY_MODES[mindex]
      METRICS_TABLE.x = 1.0 - DISPLAY_WIDTHS[@mode][0] - 0.015
      METRICS_TABLE.w = DISPLAY_WIDTHS[@mode][0]
      METRICS_TABLE.widths = DISPLAY_WIDTHS[@mode][1]
      update_all_data!
    else
      update_data_once!
      # update_totals!
    end

    if @mode != :none
      draw_tick_chart! if @has_metrics
      draw_table!
      draw_logger! if @has_logger
    end

    GTAV.wait(0)
  end
end
