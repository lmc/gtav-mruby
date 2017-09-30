# draws performance metrics onscreen
# has a tick time chart, log viewer and a table of tick times/call counts per-fiber

@message_shown_at = nil
notification_text = UiStyledText.new(font: 0, scale2: 0.25)
notification_table = UiTable.new(
  x: 0.005,
  y: 0.01,
  w: 0.17,
  rh: 0.02,
  widths: [1.0],
  p: 0.0,
  pco: 0.005,
  pci: 0.005,
  pro: 0.0,
  ta: 0,
  cell_text: notification_text,
)
GTAV.register(:VmNotifications,true) do
  
  loop do
    
    if !@message_shown_at
      if CAM::IS_SCREEN_FADED_OUT()
        GTAV.wait(100)
      else
        @message_shown_at = GTAV.time
      end
    elsif @message_shown_at > (GTAV.time - 5_000)
      notification_table.data = [
        ["#{GTAV.project_name} (asi: v#{GTAV.asi_version}, runtime: v#{GTAV.rb_version})"],
        ["https://github.com/lmc/gtav-mruby"],
        ["loaded #{GTAV.fibers.size - 1} scripts"]
      ]
      notification_table.draw
    else
      GTAV.terminate_current_fiber!
    end

    GTAV.wait(0)

  end

end
