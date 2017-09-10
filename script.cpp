/*
	THIS FILE IS A PART OF GTA V SCRIPT HOOK SDK
				http://dev-c.com			
			(C) Alexander Blade 2015
*/

#include "script.h"
#include "utils.h"

#include <io.h>
#include <fcntl.h>

#ifdef __cplusplus
extern "C" {
#endif
#include "mruby.h"
#include "mruby/irep.h"
#include "mruby/array.h"
#include "mruby/value.h"
#include "mruby/numeric.h"
#ifdef __cplusplus
}
#endif

static mrb_state *mrb;
static struct RClass *module;
static struct RClass *module_player;
static struct RClass *module_entity;


// native function wrappers

mrb_value mruby__player__player_id(mrb_state *mrb, mrb_value self) {
	Player r0 = PLAYER::PLAYER_ID();
	return mrb_fixnum_value(r0);
}

mrb_value mruby__player__player_ped_id(mrb_state *mrb, mrb_value self) {
	Ped r0 = PLAYER::PLAYER_PED_ID();
	return mrb_fixnum_value(r0);
}


mrb_value mruby__entity__get_offset_from_entity_in_world_coords(mrb_state *mrb, mrb_value self) {
	mrb_int a0;
	mrb_float a1;
	mrb_float a2;
	mrb_float a3;

	mrb_get_args(mrb, "ifff", &a0, &a1, &a2, &a3);

	Vector3 rvector3 = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(a0, a1, a2, a3);
	
	mrb_value rarray = mrb_ary_new_capa(mrb, 3);
	mrb_ary_set(mrb, rarray, 0, mrb_float_value(mrb, rvector3.x));
	mrb_ary_set(mrb, rarray, 1, mrb_float_value(mrb, rvector3.y));
	mrb_ary_set(mrb, rarray, 2, mrb_float_value(mrb, rvector3.z));
	return rarray;
}




// mruby vm helpers

// sets up the mruby vm + env
void mruby_init() {
	// create mruby VM
	mrb = mrb_open();

	// create ruby module inside VM
	module = mrb_define_module(mrb, "GTAV");
	module_player = mrb_define_module_under(mrb, module, "PLAYER");
	module_entity = mrb_define_module_under(mrb, module, "ENTITY");

	fprintf(stdout, "opening ruby\n");

	// evaluate bootstrap script
	FILE *file = fopen("./bootstrap_mrb.rb", "r");
	mrb_load_file(mrb, file);
	fclose(file);

	fprintf(stdout, "bootstrapped\n");

	// make mruby_callnative function callable from ruby
	// mrb_define_class_method(mrb, module, "callnative", mruby_callnative, MRB_ARGS_ANY());

	mrb_define_class_method(mrb, module_player, "PLAYER_ID", mruby__player__player_id, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module_player, "PLAYER_PED_ID", mruby__player__player_ped_id, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module_entity, "GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS", mruby__entity__get_offset_from_entity_in_world_coords, MRB_ARGS_REQ(4));

}

// called each tick by script engine
void mruby_tick() {
	
	Player player = PLAYER::PLAYER_ID();
	Ped playerPed = PLAYER::PLAYER_PED_ID();
	int playerExists = ENTITY::DOES_ENTITY_EXIST(playerPed);
	Vector3 coords = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(playerPed, 0.0, 5.0, 0.0);

	// call tick function defined in the ruby module
	(void)mrb_funcall(mrb, mrb_obj_value(module), "tick", 6, mrb_fixnum_value(player), mrb_fixnum_value(playerPed), mrb_fixnum_value(playerExists), mrb_float_value(mrb,coords.x), mrb_float_value(mrb,coords.y), mrb_float_value(mrb,coords.z));
}

void mruby_shutdown() {
	// shut down mruby VM
	mrb_close(mrb);
}


// console helpers

void SetStdOutToNewConsole()
{
	int hConHandle;
	long lStdHandle;
	FILE *fp;

	// Allocate a console for this app
	AllocConsole();
	AttachConsole(GetCurrentProcessId());

	freopen("CON", "w", stdout);
	freopen("CONIN$", "r", stdin);

	// Redirect unbuffered STDOUT to the console
	lStdHandle = (long)GetStdHandle(STD_OUTPUT_HANDLE);
	hConHandle = _open_osfhandle(lStdHandle, _O_TEXT);
	fp = _fdopen(hConHandle, "w");
	*stdout = *fp;

	setvbuf(stdout, NULL, _IONBF, 0);
	setbuf(stdout, NULL);
}


// script hook main loop

void main()
{	
	SetStdOutToNewConsole();
	mruby_init();
	

	while (true)
	{
		// fprintf(stdout,"updating\n");
		WAIT(100);
		mruby_tick();
	}
}

void ScriptMain()
{
	main();
}
