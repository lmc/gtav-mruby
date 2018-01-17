# use `extend self` to turn instance methods into class methods
GTAV.natives_modules.each do |mod|
  mod.send(:extend,mod)
end

GTAV.load_script('.\mruby\runtime\constants.rb')

CONFIG = {}
GTAV.load_script('.\mruby\config\defaults.rb')
GTAV.load_script('.\mruby\config\config.rb')

if CONFIG["console.enabled"]
  GTAV.spawn_console(CONFIG["console.game.x"], CONFIG["console.game.y"], CONFIG["console.game.w"], CONFIG["console.game.h"], 0,  CONFIG["console.x"], CONFIG["console.y"], CONFIG["console.w"], CONFIG["console.h"], 0)
end

GTAV.load_dir('.\mruby\vendor\mruby-io','*.rb')

GTAV.load_dir('.\mruby\runtime\classes','*.rb')

CONFIG = PersistentHash.new('.\mruby\config\config.rb','.\mruby\config\defaults.rb','CONFIG')

GTAV.load_script('.\mruby\runtime\logger.rb')             if CONFIG["runtime.use.logger"]
GTAV.load_script('.\mruby\runtime\type_methods.rb')
GTAV.load_script('.\mruby\runtime\script.rb')
GTAV.load_script('.\mruby\runtime\scheduler.rb')
GTAV.load_script('.\mruby\runtime\metrics.rb')            if CONFIG["runtime.use.metrics"]
GTAV.load_script('.\mruby\runtime\comparisons.rb')        if CONFIG["runtime.use.comparisons"]
GTAV.load_script('.\mruby\runtime\lowercase_natives.rb')

GTAV.load_dir('.\mruby\scripts','*.rb')

log "Runtime loaded"

=begin
Runtime classes/methods:

log
enum_to_hash

File
IO

PersistentHash
Queue
QueueSet

GUI::Text

GUI::Menu
GUI::Menu.new
GUI::Menu.active
GUI::Menu.draw
GUI::Menu.show(id,options)
GUI::Menu.show_submenu(id,options)
GUI::Menu.hide
GUI::Menu.hide_submenu
GUI::Menu[]

GUI::Menu::HeaderItem
GUI::Menu::HelpItem
GUI::Menu::ButtonItem
GUI::Menu::SelectItem
GUI::Menu::CheckboxItem
GUI::Menu::IntegerItem
GUI::Menu::FloatItem
GUI::Menu::ListItem

GTAV::Script
GTAV::Script#terminate!
GTAV::Script#script_index

GTAV.log
GTAV.logger_buffer

GTAV.time
GTAV.time_usec

GTAV.register
GTAV.spawn
GTAV.wait
GTAV.terminate_current_fiber!
GTAV.terminate_fiber(name)
GTAV.enable_fiber(name,enable)
GTAV.fibers
GTAV.fiber_wait_hash
GTAV.fiber_names

GTAV.metrics
GTAV.metric_register
GTAV.metric

GTAV.load_dir(dir_path,pattern)
GTAV.load_script(path)

GTAV.is_key_down
GTAV.is_key_just_up

GTAV.world_get_all_vehicles
GTAV.world_get_all_peds
GTAV.world_get_all_objects

GTAV.spawn_console

GTAV.is_syntax_valid?

GTAV.memory_base
GTAV.memory_base_size
GTAV.memory_read(address,size)
GTAV.memory_write(address,value)
GTAV.memory_protect(address,arg1,arg2)

GTAV.script_global_read(global_idx)
GTAV.script_global_write(global_idx,value)

=end