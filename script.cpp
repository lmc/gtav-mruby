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
#ifdef __cplusplus
}
#endif

static mrb_state *mrb;
static struct RClass *module;


	// sets up the mruby vm + env
	void mruby_init() {
		// create mruby VM
		mrb = mrb_open();

		// create ruby module inside VM
		module = mrb_define_module(mrb, "GTAV");

		fprintf(stdout, "opening ruby\n");

		// evaluate bootstrap script
		FILE *file = fopen("./bootstrap_mrb.rb", "r");
		mrb_load_file(mrb, file);
		fclose(file);

		fprintf(stdout, "bootstrapped\n");

		// make mruby_callnative function callable from ruby
		// mrb_define_class_method(mrb, module, "callnative", mruby_callnative, MRB_ARGS_ANY());
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

void main()
{	
	SetStdOutToNewConsole();
	mruby_init();
	mruby_tick();

	while (true)
	{
		// fprintf(stdout,"updating\n");
		WAIT(0);
	}
}

void ScriptMain()
{
	main();
}
