GTAV.register(:DebugMetrics) do

  # puts StyleText.new.inspect

  @has_metrics = !!GTAV.metrics
  @has_logger = GTAV.respond_to?(:logger_buffer)
  raise "No runtime metrics available (load runtime/runtime_metrics.rb)" if !@has_metrics

  DISPLAY_MODES = [:none,:time,:calls,:all]
  @mode = :time

  def avg(array,default = 0.0)
    num = 0
    array.each{|i| num += i}
    num /= array.size
    # num = array.inject(default){|a,i| a + i} / array.size
    num = 0.0 if num.nan?
    num
  end
  def max(array,default = 0.0)
    m = 0
    array.each{|i| m = i if i > m}
    m
  end

  def draw_text(x,y,str,options = {})
    # options[:font] = 4
    # options[:scale] = 0.5
    # UI::SET_TEXT_FONT(options[:font]) if options[:font]
    # UI::SET_TEXT_SCALE(0.0,options[:scale]) if options[:scale]
    # # UI::SET_TEXT_JUSTIFICATION(options[:align]) if options[:align]
    # UI::_SET_TEXT_ENTRY("STRING")
    # UI::_ADD_TEXT_COMPONENT_STRING(str)
    # UI::_DRAW_TEXT(x,y)
    GTAV._draw_text_many(4,0.0,0.5, 255,255,255,255, 1,0.0,1.0, true, str, x, y)
    # GTAV._draw_text_many(4,0.0,0.5, 255,255,255,255, true, str, x, y)
  end

  @data = []
  @data_update_idx = 0
  def update_data_once!
    _update_data!(@data_update_idx)
    @data_update_idx += 1
    if @data_update_idx >= @data.size - 2
      update_totals!
      @data_update_idx = 0
    end
  end
  def update_all_data!
    @data = []
    @data[0] = ["Fiber Name"]
    @data[0] += ["Avg. Time","Max Time"] if [:time,:all].include?(@mode)
    @data[0] += ["Avg. Calls","Max Calls"] if [:calls,:all].include?(@mode)
    GTAV.fiber_names.each_with_index do |name,i|
      @data[i + 1] = []
      update_data_once!
    end
    @data << []
    update_totals!
  end
  def _update_data!(idx)
    name = GTAV.fiber_names[idx]
    total_last_calls = -1

    row = []
    row << "#{idx}: #{name.to_s}"
    if [:time,:all].include?(@mode)
      # tick_times = GTAV.counters_fiber_tick_times[name].to_a
      tick_times = GTAV.metrics["fiber.#{name}.tick_times"].to_a
      row << "#{sprintf("%.3f",avg(tick_times,0.0) * 1000.0)}ms"
      row << "#{sprintf("%.3f",max(tick_times,0.0) * 1000.0)}ms"
    end
    if [:calls,:all].include?(@mode)
      # calls = GTAV.counters_fiber_calls[name].to_a
      calls = GTAV.metrics["fiber.#{name}.calls"].to_a
      row << avg(calls).to_i.to_s
      row << max(calls).to_s
    end

    # + 1 for header row
    @data[idx + 1] = row
  end
  def update_totals!
    total_last_calls = -1
    # times = GTAV.counters_tick_times
    times = GTAV.metrics["runtime.tick_times"].to_a
    @data[-1] = ["GTAV.tick Total"]
    if [:time,:all].include?(@mode)
      @data[-1] += [
        "#{sprintf("%.3f",avg(times,0.0) * 1000.0)}ms",
        "#{sprintf("%.3f",max(times,0.0) * 1000.0)}ms",
      ]
    end
    if [:calls,:all].include?(@mode)
      @data[-1] += [
        "-",
        "-",
      ]
    end
  end

  OX = 0.015 # chart x
  OY = 0.015 # chart y

  CT = 0.01 # top of bars
  CB = 0.10 # bottom of bars

  YM = 0.008  # scale value for top of bar
  BW = 0.0033 # width of each bar
  H = (CB - CT)

  ADJUSTMENT = -0.0005

  NOTICE_AT = 0.004
  def draw_tick_chart!

    times = GTAV.metrics["runtime.tick_times"].to_a
    size = times.size

    # h = (CB - CT)
    w = (BW * size)
    GRAPHICS::DRAW_RECT(OX + (w / 2.0) - (BW / 2.0),CT + (H / 2.0) + 0.005,w,H,0,0,0,127)

    times.each_with_index do |time,i|
      val = (time + ADJUSTMENT) / YM
      if time > YM
        rgba = [255,0,0,127]
      elsif time >= NOTICE_AT
        rgba = [255,255,0,127]
      else
        rgba = [0,255,0,127] 
      end
      h = CT + (val * H)
      y = CB - (val * H * 0.5)
      GRAPHICS::DRAW_RECT(OX + (BW * i),y,BW,h,*rgba)
    end

    val = NOTICE_AT / YM
    y = CB - (val * H) - 0.0055
    GRAPHICS::DRAW_RECT(OX + (w / 2.0) - (BW / 2.0),y,w,0.001,255,255,255,255)
  end

  L_OX = 0.75
  L_OY = 0.01
  L_W = 0.25
  L_H = 0.01
  L_LH = 0.025
  LOGGER_TEXT_STYLE = UiStyledText.new(font: 4, scale2: 0.3)
  def draw_logger!
    GTAV.logger_buffer.to_a.each_with_index do |message,index|
      LOGGER_TEXT_STYLE.draw("#{message}",L_OX,(L_OY + (index * L_LH)))
    end
  end

  ox = 0.01
  oy = 0.12
  xd = 0.05
  yd = 0.03
  widths = [0.1,0.05,0.05,0.05,0.05]
  update_all_data!

  table = UiTable.new
  METRICS_TEXT_STYLE = UiStyledText.new(font: 4, scale2: 0.5)
  loop do
    if GTAV.is_key_just_up(0x79) # F10
      mindex = DISPLAY_MODES.index(@mode) + 1
      mindex = 0 if mindex >= DISPLAY_MODES.size
      @mode = DISPLAY_MODES[mindex]
      update_all_data!
    else
      update_data_once!
      # update_totals!
    end

    if @mode != :none
      x = ox
      y = oy
      @data.each_with_index do |row,ri|
        row.each_with_index do |column,ci|
          # draw_text(x,y,@data[ri][ci])
          METRICS_TEXT_STYLE.draw(@data[ri][ci],x,y)
          x += widths[ci]
        end
        y += yd
        x = ox
      end
    end

    draw_tick_chart! if @has_metrics
    draw_logger! if @has_logger
    table.draw

    GTAV.wait(0)
  end
end
