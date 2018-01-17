GTAV.register(:MenuNorthYankton) do
  GTAV.wait(0)
  
  @loaded = false
  GTAV[:RuntimeMenu].register_menu_item(:MenuNorthYankton, label: ->(i){ !@loaded ? "Load North Yankton" : "Unload North Yankton" }, type: :checkbox) do |item|
    
    if @loaded
      STREAMING::REMOVE_IPL("plg_01");
      STREAMING::REMOVE_IPL("prologue01");
      STREAMING::REMOVE_IPL("prologue01_lod");
      STREAMING::REMOVE_IPL("prologue01c");
      STREAMING::REMOVE_IPL("prologue01c_lod");
      STREAMING::REMOVE_IPL("prologue01d");
      STREAMING::REMOVE_IPL("prologue01d_lod");
      STREAMING::REMOVE_IPL("prologue01e");
      STREAMING::REMOVE_IPL("prologue01e_lod");
      STREAMING::REMOVE_IPL("prologue01f");
      STREAMING::REMOVE_IPL("prologue01f_lod");
      STREAMING::REMOVE_IPL("prologue01g");
      STREAMING::REMOVE_IPL("prologue01h");
      STREAMING::REMOVE_IPL("prologue01h_lod");
      STREAMING::REMOVE_IPL("prologue01i");
      STREAMING::REMOVE_IPL("prologue01i_lod");
      STREAMING::REMOVE_IPL("prologue01j");
      STREAMING::REMOVE_IPL("prologue01j_lod");
      STREAMING::REMOVE_IPL("prologue01k");
      STREAMING::REMOVE_IPL("prologue01k_lod");
      STREAMING::REMOVE_IPL("prologue01z");
      STREAMING::REMOVE_IPL("prologue01z_lod");
      STREAMING::REMOVE_IPL("plg_02");
      STREAMING::REMOVE_IPL("prologue02");
      STREAMING::REMOVE_IPL("prologue02_lod");
      STREAMING::REMOVE_IPL("plg_03");
      STREAMING::REMOVE_IPL("prologue03");
      STREAMING::REMOVE_IPL("prologue03_lod");
      STREAMING::REMOVE_IPL("prologue03b");
      STREAMING::REMOVE_IPL("prologue03b_lod");
      STREAMING::REMOVE_IPL("prologue03_grv_cov");
      STREAMING::REMOVE_IPL("prologue03_grv_cov_lod");
      STREAMING::REMOVE_IPL("prologue03_grv_dug");
      STREAMING::REMOVE_IPL("prologue03_grv_dug_lod");
      STREAMING::REMOVE_IPL("prologue03_grv_fun");
      STREAMING::REMOVE_IPL("prologue_grv_torch");
      STREAMING::REMOVE_IPL("plg_04");
      STREAMING::REMOVE_IPL("prologue04");
      STREAMING::REMOVE_IPL("prologue04_lod");
      STREAMING::REMOVE_IPL("prologue04b");
      STREAMING::REMOVE_IPL("prologue04b_lod");
      STREAMING::REMOVE_IPL("prologue04_cover");
      STREAMING::REMOVE_IPL("des_protree_end");
      STREAMING::REMOVE_IPL("des_protree_start");
      STREAMING::REMOVE_IPL("des_protree_start_lod");
      STREAMING::REMOVE_IPL("plg_05");
      STREAMING::REMOVE_IPL("prologue05");
      STREAMING::REMOVE_IPL("prologue05_lod");
      STREAMING::REMOVE_IPL("prologue05b");
      STREAMING::REMOVE_IPL("prologue05b_lod");
      STREAMING::REMOVE_IPL("plg_06");
      STREAMING::REMOVE_IPL("prologue06");
      STREAMING::REMOVE_IPL("prologue06_lod");
      STREAMING::REMOVE_IPL("prologue06b");
      STREAMING::REMOVE_IPL("prologue06b_lod");
      STREAMING::REMOVE_IPL("prologue06_int");
      STREAMING::REMOVE_IPL("prologue06_int_lod");
      STREAMING::REMOVE_IPL("prologue06_pannel");
      STREAMING::REMOVE_IPL("prologue06_pannel_lod");
      STREAMING::REMOVE_IPL("prologue_m2_door");
      STREAMING::REMOVE_IPL("prologue_m2_door_lod");
      STREAMING::REMOVE_IPL("plg_occl_00");
      STREAMING::REMOVE_IPL("prologue_occl");
      STREAMING::REMOVE_IPL("plg_rd");
      STREAMING::REMOVE_IPL("prologuerd");
      STREAMING::REMOVE_IPL("prologuerdb");
      STREAMING::REMOVE_IPL("prologuerd_lod");
      @loaded = false
    else
      STREAMING::REQUEST_IPL("plg_01");
      STREAMING::REQUEST_IPL("prologue01");
      STREAMING::REQUEST_IPL("prologue01_lod");
      STREAMING::REQUEST_IPL("prologue01c");
      STREAMING::REQUEST_IPL("prologue01c_lod");
      STREAMING::REQUEST_IPL("prologue01d");
      STREAMING::REQUEST_IPL("prologue01d_lod");
      STREAMING::REQUEST_IPL("prologue01e");
      STREAMING::REQUEST_IPL("prologue01e_lod");
      STREAMING::REQUEST_IPL("prologue01f");
      STREAMING::REQUEST_IPL("prologue01f_lod");
      STREAMING::REQUEST_IPL("prologue01g");
      STREAMING::REQUEST_IPL("prologue01h");
      STREAMING::REQUEST_IPL("prologue01h_lod");
      STREAMING::REQUEST_IPL("prologue01i");
      STREAMING::REQUEST_IPL("prologue01i_lod");
      STREAMING::REQUEST_IPL("prologue01j");
      STREAMING::REQUEST_IPL("prologue01j_lod");
      STREAMING::REQUEST_IPL("prologue01k");
      STREAMING::REQUEST_IPL("prologue01k_lod");
      STREAMING::REQUEST_IPL("prologue01z");
      STREAMING::REQUEST_IPL("prologue01z_lod");
      STREAMING::REQUEST_IPL("plg_02");
      STREAMING::REQUEST_IPL("prologue02");
      STREAMING::REQUEST_IPL("prologue02_lod");
      STREAMING::REQUEST_IPL("plg_03");
      STREAMING::REQUEST_IPL("prologue03");
      STREAMING::REQUEST_IPL("prologue03_lod");
      STREAMING::REQUEST_IPL("prologue03b");
      STREAMING::REQUEST_IPL("prologue03b_lod");
          # //the commented code disables the 'Prologue' grave and
          # //enables the 'Bury the Hatchet' grave
      # //STREAMING::REQUEST_IPL("prologue03_grv_cov");
      # //STREAMING::REQUEST_IPL("prologue03_grv_cov_lod");
      STREAMING::REQUEST_IPL("prologue03_grv_dug");
      STREAMING::REQUEST_IPL("prologue03_grv_dug_lod");
      # //STREAMING::REQUEST_IPL("prologue03_grv_fun");
      STREAMING::REQUEST_IPL("prologue_grv_torch");
      STREAMING::REQUEST_IPL("plg_04");
      STREAMING::REQUEST_IPL("prologue04");
      STREAMING::REQUEST_IPL("prologue04_lod");
      STREAMING::REQUEST_IPL("prologue04b");
      STREAMING::REQUEST_IPL("prologue04b_lod");
      STREAMING::REQUEST_IPL("prologue04_cover");
      STREAMING::REQUEST_IPL("des_protree_end");
      STREAMING::REQUEST_IPL("des_protree_start");
      STREAMING::REQUEST_IPL("des_protree_start_lod");
      STREAMING::REQUEST_IPL("plg_05");
      STREAMING::REQUEST_IPL("prologue05");
      STREAMING::REQUEST_IPL("prologue05_lod");
      STREAMING::REQUEST_IPL("prologue05b");
      STREAMING::REQUEST_IPL("prologue05b_lod");
      STREAMING::REQUEST_IPL("plg_06");
      STREAMING::REQUEST_IPL("prologue06");
      STREAMING::REQUEST_IPL("prologue06_lod");
      STREAMING::REQUEST_IPL("prologue06b");
      STREAMING::REQUEST_IPL("prologue06b_lod");
      STREAMING::REQUEST_IPL("prologue06_int");
      STREAMING::REQUEST_IPL("prologue06_int_lod");
      STREAMING::REQUEST_IPL("prologue06_pannel");
      STREAMING::REQUEST_IPL("prologue06_pannel_lod");
      STREAMING::REQUEST_IPL("prologue_m2_door");
      STREAMING::REQUEST_IPL("prologue_m2_door_lod");
      STREAMING::REQUEST_IPL("plg_occl_00");
      STREAMING::REQUEST_IPL("prologue_occl");
      STREAMING::REQUEST_IPL("plg_rd");
      STREAMING::REQUEST_IPL("prologuerd");
      STREAMING::REQUEST_IPL("prologuerdb");
      STREAMING::REQUEST_IPL("prologuerd_lod");
      @loaded = true
    end
  end


  GTAV.terminate_current_fiber!
end
