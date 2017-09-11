/*
	THIS FILE IS A PART OF GTA V SCRIPT HOOK SDK
				http://dev-c.com			
			(C) Alexander Blade 2015
*/

#include "script.h"
#include "utils.h"

#include <io.h>
#include <string.h>
#include <fcntl.h>

#ifdef __cplusplus
extern "C" {
#endif
#include "mruby.h"
#include "mruby/irep.h"
#include "mruby/array.h"
#include "mruby/value.h"
#include "mruby/numeric.h"
#include "mruby/string.h"
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

	Vector3 cvector3 = ENTITY::GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(a0, a1, a2, a3);
	
	mrb_value rarray = mrb_ary_new_capa(mrb, 3);
	mrb_ary_set(mrb, rarray, 0, mrb_float_value(mrb, cvector3.x));
	mrb_ary_set(mrb, rarray, 1, mrb_float_value(mrb, cvector3.y));
	mrb_ary_set(mrb, rarray, 2, mrb_float_value(mrb, cvector3.z));
	//return rarray;

	mrb_value rvector3 = mrb_obj_new(mrb, mrb_class_get(mrb, "Vector3"), 0, NULL);
	(void)mrb_funcall(mrb, rvector3, "__load", 1, rarray);
	return rvector3;
}




// mruby vm helpers

void mruby_check_exception() {
	mrb_value message;
	if (mrb->exc) {
		(void)mrb_funcall(mrb, mrb_obj_value(module), "on_error", 1, mrb_obj_value(mrb->exc));
	}
}

void mruby_load_relative(char filename[]) {
	FILE *rfile;
	int error;
	rfile = fopen(filename, "r");
	if (rfile == NULL) {
		fprintf(stdout, "error opening\n");
	}
	mrb_load_file(mrb, rfile);
	if (error = ferror(rfile)) {
		fprintf(stdout, "error reading %d\n", error);
	}
	fclose(rfile);
	mruby_check_exception();
}

mrb_value mruby__gtav__load(mrb_state *mrb, mrb_value self) {
	char *filename;
	size_t filename_s;
	mrb_get_args(mrb, "s", &filename, &filename_s);
	fprintf(stdout, "mruby__gtav__load %s\n",filename);
	mruby_load_relative(filename);
	return mrb_nil_value();
}


// sets up the mruby vm + env
void mruby_init() {
	fprintf(stdout, "mruby_init\n");

	FILE *file;

	fprintf(stdout, "creating vm\n");
	mrb = mrb_open();

	fprintf(stdout, "defining modules\n");
	// create ruby module inside VM
	module = mrb_define_module(mrb, "GTAV");
	module_player = mrb_define_module_under(mrb, module, "PLAYER");
	module_entity = mrb_define_module_under(mrb, module, "ENTITY");

	fprintf(stdout, "loading bootstrap\n");

	// evaluate bootstrap script
	//file = fopen("./mruby/bootstrap.rb", "r");
	//mrb_load_file(mrb, file);
	//fclose(file);
	//mruby_check_exception();
	mruby_load_relative("./mruby/bootstrap.rb");
	fprintf(stdout, "  done\n");

	// make mruby_callnative function callable from ruby
	// mrb_define_class_method(mrb, module, "callnative", mruby_callnative, MRB_ARGS_ANY());

	fprintf(stdout, "  adding native functions\n");
	mrb_define_class_method(mrb, module, "load", mruby__gtav__load, MRB_ARGS_REQ(1));

	mrb_define_class_method(mrb, module_player, "PLAYER_ID", mruby__player__player_id, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module_player, "PLAYER_PED_ID", mruby__player__player_ped_id, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module_entity, "GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS", mruby__entity__get_offset_from_entity_in_world_coords, MRB_ARGS_REQ(4));

}

void mruby_load_scripts() {
	fprintf(stdout, "mruby_load_scripts\n");
	char filename[2048];
	int error;

	HANDLE hFind;
	WIN32_FIND_DATA FindFileData;
	if ((hFind = FindFirstFile("mruby\\scripts\\*.rb", &FindFileData)) != INVALID_HANDLE_VALUE) {
		do {
			sprintf(filename, "./mruby/scripts/%s", FindFileData.cFileName);
			fprintf(stdout, "loading %s\n", filename);
			mruby_load_relative(filename);
		} while (FindNextFile(hFind, &FindFileData));
		FindClose(hFind);
	}

}

// called each tick by script engine
void mruby_tick() {
	// call tick function defined in the ruby module
	(void)mrb_funcall(mrb, mrb_obj_value(module), "tick", 0);
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
	mruby_load_scripts();

	while (true)
	{
		WAIT(100);
		mruby_tick();
	}
}

void ScriptMain()
{
	main();
}
