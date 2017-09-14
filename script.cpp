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

static mrb_state *mrb;
static struct RClass *module;

// native function wrappers

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


// sets up the mruby vm + env
void mruby_init() {
	fprintf(stdout, "mruby_init\n");

	FILE *file;

	fprintf(stdout, "creating vm\n");
	mrb = mrb_open();

	fprintf(stdout, "loading bootstrap\n");
	module = mrb_define_module(mrb, "GTAV");
	mruby_load_relative("./mruby/bootstrap.rb");
	fprintf(stdout, "  done\n");

	fprintf(stdout, "adding native functions\n");
	mrb_define_class_method(mrb, module, "load", mruby__gtav__load, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "is_key_down", mruby__gtav__is_key_down, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "is_key_just_up", mruby__gtav__is_key_just_up, MRB_ARGS_REQ(1));

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
		WAIT(0);
		mruby_tick();
	}
}

void ScriptMain()
{
	main();
}
