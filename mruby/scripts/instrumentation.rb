GTAV.register(:Instrumentation) do

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
    GTAV.counters_fiber_calls.keys.each_with_index do |name,i|
      @data[i + 1] = []
      update_data_once!
    end
    @data << []
    update_totals!
  end
  def _update_data!(idx)
    name = GTAV.counters_fiber_calls.keys[idx]
    total_last_calls = -1

    row = []
    row << name.to_s
    if [:time,:all].include?(@mode)
      tick_times = GTAV.counters_fiber_tick_times[name].to_a
      row << "#{sprintf("%.3f",avg(tick_times,0.0) * 1000.0)}ms"
      row << "#{sprintf("%.3f",max(tick_times,0.0) * 1000.0)}ms"
    end
    if [:calls,:all].include?(@mode)
      calls = GTAV.counters_fiber_calls[name].to_a
      row << avg(calls).to_i.to_s
      row << max(calls).to_s
    end

    # + 1 for header row
    @data[idx + 1] = row
  end
  def update_totals!
    total_last_calls = -1
    times = GTAV.counters_tick_times
    @data[-1] = ["GTAV.tick Total"]
    if [:time,:all].include?(@mode)
      @data[-1] += [
        "#{sprintf("%.3f",avg(times,0.0) * 1000.0)}ms",
        "#{sprintf("%.3f",max(times,0.0) * 1000.0)}ms",
      ]
    end
    