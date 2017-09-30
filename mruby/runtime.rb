
GTAV.load_script('.\mruby\constants.rb')

CONFIG = {}
GTAV.load_script('.\mruby\config.rb')

if CONFIG["console.enabled"]
  GTAV.spawn_console(CONFIG["console.game.x"], CONFIG["console.game.y"], CONFIG["console.game.w"], CONFIG["console.game.h"], 0,  CONFIG["console.x"], CONFIG["console.y"], CONFIG["console.w"], CONFIG["console.h"], 0)
end

GTAV.load_script('.\mruby\runtime\classes.rb')

GTAV.load_script('.\mruby\runtime\runtime_logger.rb')      if CONFIG["runtime.use.logger"]
GTAV.load_script('.\mruby\runtime\runtime_fibers.rb')
GTAV.load_script('.\mruby\runtime\runtime_metrics.rb')     if CONFIG["runtime.use.metrics"]
GTAV.load_script('.\mruby\runtime\runtime_comparisons.rb') if CONFIG["runtime.use.comparisons"]
GTAV.load_script('.\mruby\runtime\ruby_call_syntax.rb')    if CONFIG["runtime.use.ruby_call_syntax"]

GTAV.load_dir('.\mruby\scripts','*.rb')

log "Runtime loaded"
