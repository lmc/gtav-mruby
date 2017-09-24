# NEXT:
# Either instrument GTAV.on_socket, or have it run in a fiber
# How's the exception handling/reporting?
# Use keycodes from config everywhere
# Ensure we're registered to unload with script-hook
# General feel of the stdlib/modules (clean it up a bit)

GTAV.load_script('.\mruby\constants.rb')

CONFIG = {}
GTAV.load_script('.\mruby\config.rb')

GTAV.load_script('.\mruby\runtime\classes.rb')

GTAV.load_script('.\mruby\runtime\runtime_logger.rb')
GTAV.load_script('.\mruby\runtime\runtime_fibers.rb')
GTAV.load_script('.\mruby\runtime\runtime_metrics.rb')
GTAV.load_script('.\mruby\runtime\runtime_comparisons.rb')

GTAV.load_script('.\mruby\runtime\runtime_socket.rb')

GTAV.load_script('.\mruby\runtime\ruby_style.rb')

# load ./scripts here
GTAV.load_dir('.\mruby\scripts','*.rb')

# BROKEN: can't seem to call these from within the script engine?
# GTAV.set_game_window(0, 0, 1920 + 4, 1080 + 25, 0)
# GTAV.set_console_window(1920 - 5, 0, 650, 1080 + 25, 0)

log "Runtime loaded"

# stdlib examples (can we compile mruby gems from a vendor dir?)

# files = Dir.glob('\dir','*.rb')

# file = File.open("filename","r")
# file.read(size = nil) # whole file
# file.write(value)
# file.seek(0)
# file.close

# server = Socket.listen(42069)
# if client = server.accept
#   if data = client.read
#     client.write("Yo")
#   else
#     client.write("Say something")
#   end
#   client.close
# end

# GTAV.pack()
# GTAV.unpack()

