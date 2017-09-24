
# lets you call native functions as `player_ped_id()` instead of `PLAYER::PLAYER_PED_ID()`

[PLAYER,PED,VEHICLE,ENTITY,GAMEPLAY,WEAPON].each do |mod|
  (mod.methods - Object.methods).each do |meth|
    eval "def #{meth.downcase}(*args); #{mod}::#{meth}(*args); end"
  end
end
