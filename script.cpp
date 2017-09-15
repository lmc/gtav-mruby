/*
	THIS FILE IS A PART OF GTA V SCRIPT HOOK SDK
				http://dev-c.com			
			(C) Alexander Blade 2015
*/

#include "script.h"
#include "utils.h"
#include "keyboard.h"

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

#include "mrubynatives.h"


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

	HWND window_game = FindWindow(NULL, "Grand Theft Auto V");
	SetWindowPos(window_game, NULL, 0, 0, 1920 + 4, 1080 + 25, 0);

	HWND window_console = GetConsoleWindow();
	RECT rect;
	GetWindowRect(window_console, &rect);
	SetWindowPos(window_console, NULL, 1920 - 5, 0, 650, 1080 + 25, 0);
}

static mrb_state *mrb;
static struct RClass *module;

// mruby vm helpers

void mruby_check_exception() {
	mrb_value message;
	if (mrb->exc) {
		mrb_value obj = mrb_obj_value(mrb->exc);
		obj = mrb_funcall(mrb, obj, "inspect", 0);
		fprintf(stdout, "error: %s\n",RSTRING_PTR(obj));
		(void)mrb_funcall(mrb, mrb_obj_value(module), "on_error", 1, mrb_obj_value(mrb->exc));
		mrb->exc = 0;
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

mrb_value mruby__gtav__spawn_console(mrb_state *mrb, mrb_value self) {
	SetStdOutToNewConsole();
	return mrb_nil_value();
}

struct memprof_userdata {
	unsigned int malloc_cnt;
	unsigned int realloc_cnt;
	unsigned int free_cnt;
	unsigned int freezero_cnt;
	unsigned long long total_size;
	unsigned int current_objcnt;
	unsigned long long current_size;
};

mrb_value mruby__gtav__world_get_all_vehicles(mrb_state *mrb, mrb_value self) {
	const int ARR_SIZE = 128;
	Vehicle arr[ARR_SIZE];
	int ret = worldGetAllVehicles(arr, ARR_SIZE);
	mrb_value rarray = mrb_ary_new_capa(mrb, ret);
	for (int i = 0; i < ret; i++) {
		mrb_ary_set(mrb, rarray, i, mrb_fixnum_value(arr[i]));
	}
	return rarray;
}


// sets up the mruby vm + env
void mruby_init() {
	fprintf(stdout, "mruby_init\n");

	FILE *file;

	fprintf(stdout, "creating vm\n");
	mrb = mrb_open();

	fprintf(stdout, "creating GTAV module and base functions\n");
	module = mrb_define_module(mrb, "GTAV");
	mrb_define_class_method(mrb, module, "load", mruby__gtav__load, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "is_key_down", mruby__gtav__is_key_down, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "is_key_just_up", mruby__gtav__is_key_just_up, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "set_call_limit", mruby__gtav__set_call_limit, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "get_call_limit", mruby__gtav__get_call_limit, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "spawn_console", mruby__gtav__spawn_console, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "world_get_all_vehicles", mruby__gtav__world_get_all_vehicles, MRB_ARGS_NONE());


	fprintf(stdout, "loading bootstrap\n");
	mruby_load_relative("./mruby/bootstrap.rb");
	fprintf(stdout, "  done\n");

	fprintf(stdout, "adding native functions\n");
	mruby_install_natives(mrb);
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
			(void)mrb_funcall(mrb, mrb_obj_value(module), "load_script", 1, mrb_str_new_cstr(mrb, filename));
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




// script hook main loop

void main()
{	
	FILE *rfile = fopen("./mruby/console-enabled", "r");
	if (rfile) {
		fclose(rfile);
		SetStdOutToNewConsole();
	}

	mruby_init();
	mruby_load_scripts();
	fprintf(stdout, "beginning main loop\n");

	while (true)
	{
		WAIT(0);
		mruby_tick();
	}
}

void ScriptMain()
{
	main();
}
