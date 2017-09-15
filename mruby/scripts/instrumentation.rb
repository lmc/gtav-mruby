GTAV.register(:Instrumentation) do

  def avg(array,default = 0.0)
    num = array.inject(default){|a,i| a + i} / array.size
    num = 0.0 if num.nan?
    num
  end
  def max(array,default = 0.0)
    m = 0
    array.each{|i| m = i if i > m}
    m
  end

  def draw_text(x,y,str,options = {})
    options[:font] = 4
    options[:scale] = 0.5
    UI::SET_TEXT_FONT(options[:font]) if options[:font]
    UI::SET_TEXT_SCALE(0.0,options[:scale]) if options[:scale]
    # UI::SET_TEXT_JUSTIFICATION(options[:align]) if options[:align]
    UI::_SET_TEXT_ENTRY("STRING")
    UI::_ADD_TEXT_COMPONENT_STRING(str)
    UI::_DRAW_TEXT(x,y)
  end

  @data = []
  @data[0] = ["Fiber Name","Avg. Time","Avg. Calls","Max Time","Max Calls"]
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
    GTAV.counters_fiber_calls.keys.each_with_index do |name,i|
      @data[i + 1] = []
      update_data_once!
    end
    @data << []
    update_totals!
  end
  def _update_data!(idx)
    name = GTAV.counters_fiber_calls.keys[idx]
    times = GTAV.counters_tick_times
    total_last_calls = -1

    calls = GTAV.counters_fiber_calls[name].to_a
    tick_times = GTAV.counters_fiber_tick_times[name].to_a

    row = [
      "#{name}",
      "#{(avg(tick_times,0.0) * 1000.0).round(3)}ms",
      "#{avg(calls).to_i}",
      "#{(max(tick_times) * 1000.0).round(3)}",
      "#{max(calls)}"
    ]

    # + 1 for header row
    @data[idx + 1] = row
  end
  def update_totals!
    total_last_calls = -1
    times = GTAV.counters_tick_times
    @data[-1] = [
      "GTAV.tick Total",
      "#{(avg(times,0.0) * 1000.0).round(3)}ms",
      "#{total_last_calls}",
      "#{(max(times,0) * 1000.0).round(3)}ms",
      "-"
    ]
  end

  ox = 0.01
  oy = 0.01
  xd = 0.05
  yd = 0.03
  widths = [0.1,0.05,0.05,0.05,0.05]
  update_all_data!

  loop do
    update_data_once!

    x = ox
    y = oy
    @data.each_with_index do |row,ri|
      row.each_with_index do |column,ci|
        draw_text(x,y,@data[ri][ci])
        x += widths[ci]
      end
      y += yd
      x = ox
    end

    GTAV.wait(0)
  end
end
