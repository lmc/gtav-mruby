# draws performance metrics onscreen
# has a tick time chart, log viewer and a table of tick times/call counts per-fiber

# GTAV.register(:LoadNotification,CONFIG["scripts.LoadNotification.enabled"]) do
@message_shown_at = nil
notification_text = UiStyledText.new(font: 0, scale2: 0.25)
notification_table = UiTable.new(
  x: 0.01,
  y: 0.01,
  w: 0.25,
  rh: 0.02,
  widths: [1.0],
  p: 0.005,
  pco: 0.005,
  pci: 0.005,
  pro: 0.005,
  ta: 0,
  cell_text: notification_text,
)
GTAV.register(:VmNotifications,false) do
  GTAV.wait(0)
  
  loop do
    
    if !@message_shown_at
      if CAM::IS_SCREEN_FADED_OUT()
        GTAV.wait(100)
      else
        @message_shown_at = GTAV.time
      end
    elsif @message_shown_at > (GTAV.time - 5_000)
      notification_table.data = [["gtav-mruby loaded #{GTAV.fibers.size - 1} scripts (asi: v#{GTAV.asi_version}, runtime: v#{GTAV.rb_version})"]]
      notification_table.data = [["gtav-mruby loaded 299 scripts (asi: v10.0.10, runtime: v10.0.10)"]]
      notification_table.draw
    else
      GTAV.terminate_current_fiber!
    end

    GTAV.wait(0)

  end

end
