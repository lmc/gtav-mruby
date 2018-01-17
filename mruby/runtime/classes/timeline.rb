
class Timeline
  def initialize(&block)
    @timeline = []
    @start = nil
    yield(self)
  end

  def at(ms,&block)
    @timeline << {start: ms, end: nil, block: block}
  end

  def during(ms_s,ms_e,&block)
    @timeline << {start: ms_s, end: ms_e, block: block}    
  end

  def advance_to(ms)
    @advance = ms
  end

  def start(start = GTAV.time)
    @start = start
    @advance = 0
    @timeline = @timeline.sort_by{|rule| rule[:start]}
  end

  def tick(now = GTAV.time)
    start(now) if !@start
    now -= (@start - @advance)
    @timeline.each_with_index do |rule,index|
      if rule[:start] < now
        if rule[:end]
          if rule[:end] < now
            # if end time has passed, delete this rule
            @timeline[index] = nil
          else
            # otherwise it's still active, so call it
            rule[:block].call
          end
        else
          # if there's no end time, it's a one-shot, so call then delete
          rule[:block].call
          @timeline[index] = nil
        end
      end
    end
    @timeline.compact!
  end
end
