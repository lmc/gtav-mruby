# draws performance metrics onscreen
# has a tick time chart, log viewer and a table of tick times/call counts per-fiber

GTAV.register(:RuntimeMetrics,CONFIG["scripts.RuntimeMetrics.enabled"]) do

  MenuRuntimeMetrics = GUI::Menu.new({
    id: :MenuRuntimeMetrics,
    x: 1.0 - 0.21,
    y: 0.01 + 0.02 + 0.11,
    w: 0.2
  })

  MenuRuntimeMetrics.items do |items|
    items << { type: :button, label: ->(i){
      [
        [ :cell , "Ruby Tick Avg/Max" , { w: 0.5 } ],
        [ :right ],
        [ :cell , "#{METRICS_TABLE.data[-1][2]}" , { w: 0.25 } ],
        [ :cell , "#{METRICS_TABLE.data[-1][1]}" , { w: 0.25 } ],
      ]
    } }
    items << { type: :help, default: ->(i){
      if @mode != :new2
        GTAV.logger_buffer.array.last(5).join("\n")
      end
    } }
  end

  MenuRuntimeMetrics.show(selected: false)

  @has_metrics = !!GTAV.metrics
  @has_logger = GTAV.respond_to?(:logger_buffer)
  raise "No runtime metrics available (load runtime/metrics.rb)" if !@has_metrics

  DISPLAY_MODES = [:none,:minimal,:time,:calls,:objects,:all,:new,:new2]
  DISPLAY_WIDTHS = {
    :none => [0.2,[1.0]],
    :minimal => [0.2,[0.5,0.25,0.25]],
    :time => [0.2,[0.5,0.25,0.25]],
    :calls => [0.2,[0.5,0.25,0.25]],
    :objects => [0.2,[0.5,0.25,0.25]],
    :all => [0.3,[0.4,0.15,0.15,0.15,0.15]],
    :new => [0.2,[1.0]],
    :new2 => [0.2,[1.0]],
  }
  @mode = :none
  # @mode = :time

  TICK_CHART = UiBarChart.new(x: 1.0 - 0.2075, y: 0.01 + 0.035, w: 0.2, h: 0.09, limits: [0.0,0.005])
  TICK_CHART_LT = UiBarChart.new(x: 1.0 - 0.2075 - 0.3, y: 0.01 + 0.035, w: 0.2, h: 0.09, limits: [0.0,0.005])

  METRICS_HEADER_TEXT_STYLE = GUI::Text.new(font: 4, scale2: 0.42)
  METRICS_VALUE_TEXT_STYLE = GUI::Text.new(font: 5, scale2: 0.42, proportional: false)
  METRICS_TABLE = UiTable.new(
    x: 1.0 - 0.195,
    y: 0.12 + 0.02,
    w: 0.2,
    rh: 0.03,
    widths: [0.5,0.25,0.25],
    p: 0.005,
    pco: 0.005,
    pci: 0.005,
    pro: 0.005,
    cell_text: METRICS_HEADER_TEXT_STYLE,
  )

  LOGGER_TEXT_STYLE = GUI::Text.new(font: 0, scale2: 0.3)
  LOGGER_TABLE = UiTable.new(
    x: 1.0 - 0.2 - 0.015,
    y: 0.12,
    w: 0.2,
    rh: 0.02,
    p: 0.005,
    pco: 0.005,
    pci: 0.005,
    pro: 0.001,
    pri: -0.002,
    cell_text: LOGGER_TEXT_STYLE
  )

  GTAV.metrics.metric_register("runtime.tick_times_long",60)


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
    if [:minimal,:new,:new2].include?(@mode)
      update_totals! if @data_update_idx == 0
      @data_update_idx += 1
      @data_update_idx = 0 if @data_update_idx > 10
    else
      _update_data!(@data_update_idx)
      @data_update_idx += 1
      if @data_update_idx >= METRICS_TABLE.data.size - 2
        update_totals!
        @data_update_idx = 0
      end
    end
  end

  def update_all_data!
    METRICS_TABLE.data = [[]]
    METRICS_TABLE.data[0] = ["Fiber Name"]
    METRICS_TABLE.data[0] += ["Avg. Time","Max Time"] if [:time,:all,:new,:new2].include?(@mode)
    METRICS_TABLE.data[0] += ["Avg. Calls","Max Calls"] if [:calls,:all,:new,:new2].include?(@mode)
    METRICS_TABLE.data[0] += ["Avg. Objs","Max Objs"] if [:objects,:all,:new,:new2].include?(@mode)
    if @mode == :minimal

    else
      GTAV.fibers.each_with_index do |name,i|
        METRICS_TABLE.data[i + 1] = []
        update_data_once!
      end
      METRICS_TABLE.data << []
      update_totals!
    end
  end

  def _update_data!(idx)
    name = GTAV.fibers[idx].script_name
    total_last_calls = -1

    row = []
    # row << "#{idx}: #{name.to_s}"
    row << "#{name.to_s}"
    if [:time,:all].include?(@mode) && GTAV.metrics["fiber.#{name}.tick_times"]
      tick_times = GTAV.metrics["fiber.#{name}.tick_times"].array
      row << "#{sprintf("%.3f",avg(tick_times,0.0) * 1000.0)}ms"
      row << "#{sprintf("%.3f",max(tick_times,0.0) * 1000.0)}ms"
    end
    if [:calls,:all].include?(@mode) && GTAV.metrics["fiber.#{name}.calls"]
      calls = GTAV.metrics["fiber.#{name}.calls"].array
      row << avg(calls).to_i.to_s
      row << max(calls).to_s
    end
    if [:objects,:all].include?(@mode) && GTAV.metrics["fiber.#{name}.objects"]
      calls = GTAV.metrics["fiber.#{name}.objects"].array
      row << avg(calls).to_i.to_s
      row << max(calls).to_s
    end

    # + 1 for header row
    METRICS_TABLE.data[idx + 1] = row
  end

  @totals_ticks = 0
  def update_totals!
    total_last_calls = -1
    times = GTAV.metrics["runtime.tick_times"].array
    METRICS_TABLE.data[-1] = ["GTAV.tick Total"]
    if [:minimal,:time,:all,:new,:new2].include?(@mode)
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
    @totals_ticks += 1
    if @totals_ticks > 6
      GTAV.metrics.metric("runtime.tick_times_long").push( avg(times,0.0) )
      @totals_ticks = 0
    end
  end

  def draw_tick_chart!
    TICK_CHART.data = GTAV.metrics["runtime.tick_times"].array
    TICK_CHART.draw
    TICK_CHART_LT.data = GTAV.metrics["runtime.tick_times_long"].array
    TICK_CHART_LT.draw if @mode != :new2
  end

  def draw_table!
    METRICS_TABLE.draw
  end

  def draw_logger!
    LOGGER_TABLE.data = GTAV.logger_buffer.array.last(5).map{|b| [b]}
    LOGGER_TABLE.draw if @mode != :new2
  end

  def set_mode(mode)
    @mode = mode
    METRICS_TABLE.x = 1.0 - DISPLAY_WIDTHS[@mode][0] - 0.015
    METRICS_TABLE.w = DISPLAY_WIDTHS[@mode][0]
    METRICS_TABLE.widths = DISPLAY_WIDTHS[@mode][1]
    update_all_data!
  end

  update_all_data!

  GTAV.wait(0)
  GTAV[:RuntimeHost].register_menu_item(:RuntimeMetrics, label: "Metrics", type: :select, collection: Hash[DISPLAY_MODES.map{|m| [m,m] }], value: @mode) do |item|
    set_mode(item.value)
  end

  loop do
    if false && GTAV.is_key_just_up(CONFIG["scripts.RuntimeMetrics.key"]) # F10
      mindex = DISPLAY_MODES.index(@mode) + 1
      mindex = 0 if mindex >= DISPLAY_MODES.size
      set_mode( DISPLAY_MODES[mindex] )
    else
      update_data_once!
      # update_totals!
    end

    if @mode != :none
      draw_tick_chart! if @has_metrics
      if @mode == :new || @mode == :new2
        MenuRuntimeMetrics.update_help()
        MenuRuntimeMetrics.draw()
      else
        draw_table!
        # draw_logger! if @has_logger
      end
    end

    GTAV.wait(0)
  end
end
