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
	SetWindowPos(window_console, NULL, 1920 - 5, 0, 650, 1080 + 25, 0);
}

static BOOL reset_mruby_next_tick = true;
static int reset_confirm_ticks = 0;
static mrb_state *mrb;
static struct RClass *module;

// mruby vm helpers

void mruby_check_exception() {
	if (mrb->exc) {
		mrb_value obj = mrb_obj_value(mrb->exc);
		obj = mrb_funcall(mrb, obj, "inspect", 0);
		fprintf(stdout, "error: %s\n",RSTRING_PTR(obj));
		(void)mrb_funcall(mrb, mrb_obj_value(module), "on_error", 1, mrb_obj_value(mrb->exc));
		mrb->exc = 0;
	}
}

BOOL mruby_load_relative(char filename[]) {
	//fprintf(stdout, "mruby_load_relative %s\n", filename);

	FILE *rfile;
	rfile = fopen(filename, "r");
	if (rfile == NULL) {
		fprintf(stdout, "error opening\n");
		return false;
	}

	mrb->exc = 0;

	mrbc_context *cxt = mrbc_context_new(mrb);
	mrbc_filename(mrb, cxt, filename);
	cxt->capture_errors = true;

	mrb_parser_state *parser = mrb_parse_file(mrb, rfile, cxt);
	fclose(rfile);

	BOOL ret = false;
	if (parser->nerr > 0) {
		fprintf(stdout, "ERROR: %s:%d: %s (error %d)\n", filename, parser->error_buffer[0].lineno, parser->error_buffer[0].message, parser->nerr);
	}
	else {
		rfile = fopen(filename, "r");
		if (rfile == NULL) {
			fprintf(stdout, "error opening\n");
			return false;
		}
		mrb_load_file_cxt(mrb, rfile, cxt);
		fclose(rfile);
		if (!mrb->exc) {
			ret = true;
		}
	}

	mruby_check_exception();
	mrb_parser_free(parser);
	mrbc_context_free(mrb, cxt);
	return ret;
}


mrb_value mruby__gtav__set_game_window(mrb_state *mrb, mrb_value self) {
	mrb_int a0, a1, a2, a3, a4;
	mrb_get_args(mrb, "iiiii", &a0, &a1, &a2, &a3, &a4);
	fprintf(stdout, "set_game_window %i %i %i %i %i\n", a0, a1, a2, a3, a4);
	HWND window = FindWindow(NULL, "Grand Theft Auto V");
	fprintf(stdout, "set_game_window window %i\n", window);
	SetWindowPos(window, NULL, a0, a1, a2, a3, a4);
	return mrb_nil_value();
}

mrb_value mruby__gtav__set_console_window(mrb_state *mrb, mrb_value self) {
	mrb_int a0, a1, a2, a3, a4;
	mrb_get_args(mrb, "iiiii", &a0, &a1, &a2, &a3, &a4);
	HWND window = GetConsoleWindow();
	SetWindowPos(window, NULL, a0, a1, a2, a3, a4);
	return mrb_nil_value();
}

mrb_value mruby__gtav__load(mrb_state *mrb, mrb_value self) {
	char *filename;
	size_t filename_s;
	mrb_get_args(mrb, "s", &filename, &filename_s);
	//fprintf(stdout, "mruby__gtav__load %s\n",filename);
	BOOL ret = mruby_load_relative(filename);
	return mrb_bool_value(ret);
}

mrb_value mruby__gtav__load_dir(mrb_state *mrb, mrb_value self) {
	char *dirname;
	size_t dirname_s;
	char *pattern;
	size_t pattern_s;
	mrb_get_args(mrb, "ss", &dirname, &dirname_s, &pattern, &pattern_s);
	
	//fprintf(stdout, "mruby__gtav__load_dir %s , %s\n", dirname, pattern);
	char filename[2048];

	char dirpattern[1024];
	sprintf(dirpattern, "%s\\%s", dirname, pattern);
	//fprintf(stdout, "dirpattern %s\n", dirpattern);

	HANDLE hFind;
	WIN32_FIND_DATA FindFileData;
	if ((hFind = FindFirstFile(dirpattern, &FindFileData)) != INVALID_HANDLE_VALUE) {
		do {
			sprintf(filename, "%s/%s", dirname, FindFileData.cFileName);
			//fprintf(stdout, "filename %s\n", filename);
			(void)mrb_funcall(mrb, mrb_obj_value(module), "load_script", 1, mrb_str_new_cstr(mrb, filename));
		} while (FindNextFile(hFind, &FindFileData));
		FindClose(hFind);
	}

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

mrb_value mruby__gtav___draw_text_many(mrb_state *mrb, mrb_value self) {
	mrb_int font;
	mrb_float scale1;
	mrb_float scale2;
	mrb_int c_r;
	mrb_int c_g;
	mrb_int c_b;
	mrb_int c_a;
	//mrb_int alignment;
	//mrb_float wrap_x;
	//mrb_float wrap_y;
	mrb_bool proportional;
	char* str;
	int str_len;
	mrb_float x;
	mrb_float y;
	mrb_get_args(mrb, "iffiiiibsff", &font, &scale1, &scale2, &c_r, &c_g, &c_b, &c_a, &proportional, &str, &str_len, &x, &y);
	UI::SET_TEXT_FONT(font);
	UI::SET_TEXT_SCALE(scale1, scale2);
	UI::SET_TEXT_COLOUR(c_r, c_g, c_b, c_a);
	//UI::SET_TEXT_JUSTIFICATION(alignment);
	//UI::SET_TEXT_WRAP(wrap_x, wrap_y);
	UI::SET_TEXT_PROPORTIONAL(proportional);
	UI::_SET_TEXT_ENTRY("STRING");
	UI::_ADD_TEXT_COMPONENT_STRING(str);
	UI::_DRAW_TEXT(x, y);
	return mrb_nil_value();
}

mrb_value mruby__gtav__reset_mruby_next_tick(mrb_state *mrb, mrb_value self) {
	reset_mruby_next_tick = true;
	return mrb_nil_value();
}



// sets up the mruby vm + env
void mruby_init() {
	fprintf(stdout, "mruby_init\n");

	fprintf(stdout, "creating vm\n");
	mrb = mrb_open();

	fprintf(stdout, "creating GTAV module and base functions\n");
	module = mrb_define_module(mrb, "GTAV");
	mrb_define_class_method(mrb, module, "load", mruby__gtav__load, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "load_dir", mruby__gtav__load_dir, MRB_ARGS_REQ(2));
	mrb_define_class_method(mrb, module, "is_key_down", mruby__gtav__is_key_down, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "is_key_just_up", mruby__gtav__is_key_just_up, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "set_call_limit", mruby__gtav__set_call_limit, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "get_call_limit", mruby__gtav__get_call_limit, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "spawn_console", mruby__gtav__spawn_console, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "world_get_all_vehicles", mruby__gtav__world_get_all_vehicles, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "world_get_all_peds", mruby__gtav__world_get_all_peds, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "world_get_all_objects", mruby__gtav__world_get_all_objects, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "_draw_text_many", mruby__gtav___draw_text_many, MRB_ARGS_REQ(11));
	mrb_define_class_method(mrb, module, "reset_mruby_next_tick!", mruby__gtav__reset_mruby_next_tick, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "set_game_window", mruby__gtav__set_game_window, MRB_ARGS_REQ(5));
	mrb_define_class_method(mrb, module, "set_console_window", mruby__gtav__set_console_window, MRB_ARGS_REQ(5));


	fprintf(stdout, "loading bootstrap\n");
	mruby_load_relative("./mruby/bootstrap.rb");

	fprintf(stdout, "adding native functions\n");
	mruby_install_natives(mrb);

	fprintf(stdout, "loading runtime\n");
	mruby_load_relative("./mruby/runtime.rb");
}

void mruby_load_scripts() {
	fprintf(stdout, "mruby_load_scripts\n");
	char filename[2048];

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

	fprintf(stdout, "beginning main loop\n");

	while (true)
	{
		// F11
		if (IsKeyDown(0x7A)) {
			reset_confirm_ticks++;
		}
		else {
			reset_confirm_ticks = 0;
		}
		if (reset_confirm_ticks > 100) {
			reset_confirm_ticks = 0;
			reset_mruby_next_tick = true;
		}

		if (reset_mruby_next_tick) {
			fprintf(stdout, "RESETTING MRUBY\n");
			reset_mruby_next_tick = false;
			if (mrb) {
				mruby_shutdown();
			}
			mruby_init();
			// mruby_load_scripts();
		}

		mruby_tick();
		WAIT(0);
	}
}

void ScriptMain()
{
	main();
}
