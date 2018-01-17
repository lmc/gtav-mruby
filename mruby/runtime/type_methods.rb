
def Player(*args)
  GTAV::Player.new(*args)
end

def Ped(*args)
  GTAV::Ped.new(*args)
end

def Vehicle(*args)
  GTAV::Vehicle.new(*args)
end

def Entity(*args)
  GTAV::Entity.new(*args)
end

def Hash(*args)
  if args.size == 1 && args[0].is_a?(Fixnum)
    GTAV::Hash.new(*args)
  else
    super
  end
end

def Vector3(*args)
  GTAV::Vector3.new(*args)
end