
mrb_value mruby__gtav__is_key_down(mrb_state *mrb, mrb_value self) {
	mrb_int a0;
	mrb_get_args(mrb, "i", &a0);
	mrb_bool r0 = IsKeyDown(a0);
	return mrb_bool_value(r0);
}
mrb_value mruby__gtav__is_key_just_up(mrb_state *mrb, mrb_value self) {
	mrb_int a0;
	mrb_get_args(mrb, "i", &a0);
	mrb_bool r0 = IsKeyJustUp(a0);
	return mrb_bool_value(r0);
}

mrb_value mruby__gtav__world_get_all_vehicles(mrb_state *mrb, mrb_value self) {
	const int ARR_SIZE = 1024;
	Vehicle arr[ARR_SIZE];
	int ret = worldGetAllVehicles(arr, ARR_SIZE);
	mrb_value rarray = mrb_ary_new_capa(mrb, ret);
	for (int i = 0; i < ret; i++) {
		mrb_ary_set(mrb, rarray, i, mrb_fixnum_value(arr[i]));
	}
	return rarray;
}

mrb_value mruby__gtav__world_get_all_peds(mrb_state *mrb, mrb_value self) {
	const int ARR_SIZE = 1024;
	Ped arr[ARR_SIZE];
	int ret = worldGetAllPeds(arr, ARR_SIZE);
	mrb_value rarray = mrb_ary_new_capa(mrb, ret);
	for (int i = 0; i < ret; i++) {
		mrb_ary_set(mrb, rarray, i, mrb_fixnum_value(arr[i]));
	}
	return rarray;
}

mrb_value mruby__gtav__world_get_all_objects(mrb_state *mrb, mrb_value self) {
	const int ARR_SIZE = 1024;
	Ped arr[ARR_SIZE];
	int ret = worldGetAllObjects(arr, ARR_SIZE);
	mrb_value rarray = mrb_ary_new_capa(mrb, ret);
	for (int i = 0; i < ret; i++) {
		mrb_ary_set(mrb, rarray, i, mrb_fixnum_value(arr[i]));
	}
	return rarray;
}
