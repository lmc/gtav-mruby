GTAV.load_script('.\mruby\constants.rb')

CONFIG = {}
GTAV.load_script('.\mruby\config.rb')

GTAV.load_script('.\mruby\runtime\classes.rb')

GTAV.load_script('.\mruby\runtime\runtime_logger.rb')
GTAV.load_script('.\mruby\runtime\runtime_fibers.rb')
GTAV.load_script('.\mruby\runtime\runtime_metrics.rb')
GTAV.load_script('.\mruby\runtime\runtime_comparisons.rb')

GTAV.load_script('.\mruby\runtime\runtime_socket.rb')

# load ./scripts here
GTAV.load_dir('.\mruby\scripts','*.rb')

# BROKEN: can't seem to call these from within the script engine?
# GTAV.set_game_window(0, 0, 1920 + 4, 1080 + 25, 0)
# GTAV.set_console_window(1920 - 5, 0, 650, 1080 + 25, 0)

log "Runtime loaded"
