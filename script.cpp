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
#include <Psapi.h>

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

//#include "vendor/mruby-tiny-io/src/tinyio.c"

#include "vendor\mruby-io\src\file.c"
#include "vendor\mruby-io\src\file_test.c"
#include "vendor\mruby-io\src\io.c"
#include "vendor\mruby-pack\src\pack.c"



static BOOL reset_mruby_next_tick = true;
static int reset_confirm_ticks = 0;
static mrb_state *mrb;
static struct RClass *module;

void mruby_check_exception() {
	if (mrb->exc) {
		mrb_value obj = mrb_obj_value(mrb->exc);
		obj = mrb_funcall(mrb, obj, "inspect", 0);
		fprintf(stdout, "error: %s\n", RSTRING_PTR(obj));
		(void)mrb_funcall(mrb, mrb_obj_value(module), "on_error", 1, mrb_obj_value(mrb->exc));
		mrb->exc = 0;
	}
}

#include "mruby_console.cpp"
#include "mruby_load.cpp"
#include "mruby_hooks.cpp"
#include "mruby_socket.cpp"


mrb_value mruby__gtav___draw_text_many(mrb_state *mrb, mrb_value self) {
	mrb_int font;
	mrb_float scale1;
	mrb_float scale2;
	mrb_int c_r;
	mrb_int c_g;
	mrb_int c_b;
	mrb_int c_a;
	mrb_int alignment;
	mrb_float wrap_x;
	mrb_float wrap_y;
	mrb_bool proportional;
	char* str;
	int str_len;
	mrb_float x;
	mrb_float y;
	mrb_get_args(mrb, "iffiiiiiffbsff", &font, &scale1, &scale2, &c_r, &c_g, &c_b, &c_a, &alignment, &wrap_x, &wrap_y, &proportional, &str, &str_len, &x, &y);
	UI::SET_TEXT_FONT(font);
	UI::SET_TEXT_SCALE(scale1, scale2);
	UI::SET_TEXT_COLOUR(c_r, c_g, c_b, c_a);
	UI::SET_TEXT_JUSTIFICATION(alignment);
	UI::SET_TEXT_WRAP(wrap_x, wrap_y);
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


mrb_value mruby__gtav__memory_base(mrb_state *mrb, mrb_value self) {
	intptr_t pBase = (intptr_t)GetModuleHandle(nullptr);
	return mrb_fixnum_value(pBase);
}
mrb_value mruby__gtav__memory_base_size(mrb_state *mrb, mrb_value self) {
	intptr_t pBase = (intptr_t)GetModuleHandle(nullptr);
	uint32_t pSize = 0;

	MODULEINFO info;
	GetModuleInformation(GetCurrentProcess(), (HMODULE)pBase, &info, sizeof(MODULEINFO));
	pSize = info.SizeOfImage;
	return mrb_fixnum_value(pSize);
}

mrb_value mruby__gtav__memory_read(mrb_state *mrb, mrb_value self) {
	long long address;
	int size;
	mrb_get_args(mrb, "ii", &address, &size);
	//char* value = new char[size + 1];
	char* value = new char[size];
	memcpy(value, (const void *)address, size);
	//value[size] = '\0';
	return mrb_str_new(mrb, value, size);
}

mrb_value mruby__gtav__memory_write(mrb_state *mrb, mrb_value self) {
	long long address;
	char* value;
	int size;
	mrb_get_args(mrb, "is", &address, &value, &size);
	memcpy((void *)address, value, size);
	return mrb_nil_value();
}

mrb_value mruby__gtav__memory_protect(mrb_state *mrb, mrb_value self) {
	long long address;
	int arg1, arg2;
	mrb_get_args(mrb, "iii", &address, &arg1, &arg2);
	VirtualProtect((void *)address, arg1, arg2, nullptr);
	return mrb_nil_value();
}

mrb_value mruby__gtav__script_global_read(mrb_state *mrb, mrb_value self) {
	int global_idx;
	int size = 8;
	mrb_get_args(mrb, "i", &global_idx);
	UINT64* address = getGlobalPtr(global_idx);
	char* value = new char[size];
	memcpy(value, (const void *)address, size);
	return mrb_str_new(mrb, value, size);
}

mrb_value mruby__gtav__script_global_write(mrb_state *mrb, mrb_value self) {
	int global_idx;
	int size;
	char* value;
	mrb_get_args(mrb, "is", &global_idx, &value, &size);
	size = 8;
	UINT64* address = getGlobalPtr(global_idx);
	mrb_get_args(mrb, "is", &address, &value, &size);
	memcpy((void *)address, value, size);
	return mrb_nil_value();
}

mrb_value mruby__gtav__script_object_address(mrb_state *mrb, mrb_value self) {
	int script_object_id;
	mrb_get_args(mrb, "i", &script_object_id);
	BYTE *address = getScriptHandleBaseAddress(script_object_id);
	return mrb_fixnum_value((long long)address);
}

mrb_value mruby__gtav__game_version(mrb_state *mrb, mrb_value self) {
	return mrb_fixnum_value( getGameVersion() );
}

mrb_value mruby__gtav__screen_bmp(mrb_state *mrb, mrb_value self) {
	
	HWND DesktopHwnd = FindWindow(NULL, "Grand Theft Auto V");
	fprintf(stdout, "mruby__gtav__screen_bmp: hwnd %d\n", DesktopHwnd);

	//HWND DesktopHwnd = GetDesktopWindow();
	RECT DesktopParams;
	HDC DevC = GetDC(DesktopHwnd);
	GetWindowRect(DesktopHwnd,&DesktopParams);
	DWORD Width = DesktopParams.right - DesktopParams.left - 4 - 2;
	DWORD Height = DesktopParams.bottom - DesktopParams.top - 25 - 4;

	DWORD FileSize = sizeof(BITMAPFILEHEADER)+sizeof(BITMAPINFOHEADER)+(sizeof(RGBTRIPLE)+1*(Width*Height*4));
	char *BmpFileData = (char*)GlobalAlloc(0x0040,FileSize);
	//fprintf(stdout, "mruby__gtav__screen_bmp: FileSize %d\n", FileSize);


	PBITMAPFILEHEADER BFileHeader = (PBITMAPFILEHEADER)BmpFileData;
	PBITMAPINFOHEADER  BInfoHeader = (PBITMAPINFOHEADER)&BmpFileData[sizeof(BITMAPFILEHEADER)];

	BFileHeader->bfType = 0x4D42; // BM
	BFileHeader->bfSize = sizeof(BITMAPFILEHEADER);
	BFileHeader->bfOffBits = sizeof(BITMAPFILEHEADER)+sizeof(BITMAPINFOHEADER);

	BInfoHeader->biSize = sizeof(BITMAPINFOHEADER);
	BInfoHeader->biPlanes = 1;
	BInfoHeader->biBitCount = 24;
	BInfoHeader->biCompression = BI_RGB;
	BInfoHeader->biHeight = Height;
	BInfoHeader->biWidth = Width;

	RGBTRIPLE *Image = (RGBTRIPLE*)&BmpFileData[sizeof(BITMAPFILEHEADER)+sizeof(BITMAPINFOHEADER)];
	RGBTRIPLE color;
	
	HDC CaptureDC = CreateCompatibleDC(DevC);
	HBITMAP CaptureBitmap = CreateCompatibleBitmap(DevC,Width,Height);
	SelectObject(CaptureDC,CaptureBitmap);
	BitBlt(CaptureDC,0,0,Width,Height,DevC,0,0,SRCCOPY|CAPTUREBLT);
	GetDIBits(CaptureDC,CaptureBitmap,0,Height,Image,(LPBITMAPINFO)BInfoHeader, DIB_RGB_COLORS);

	mrb_value ret = mrb_str_new(mrb, BmpFileData, FileSize);

    GlobalFree(BmpFileData);

	return ret;

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
	mrb_define_class_method(mrb, module, "is_key_just_up_inclusive", mruby__gtav__is_key_just_up_inclusive, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "is_key_just_up_exclusive", mruby__gtav__is_key_just_up_exclusive, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "key_just_up", mruby__gtav__key_just_up, MRB_ARGS_NONE(0));
	mrb_define_class_method(mrb, module, "set_call_limit", mruby__gtav__set_call_limit, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "get_call_limit", mruby__gtav__get_call_limit, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "spawn_console", mruby__gtav__spawn_console, MRB_ARGS_REQ(10));
	mrb_define_class_method(mrb, module, "world_get_all_vehicles", mruby__gtav__world_get_all_vehicles, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "world_get_all_peds", mruby__gtav__world_get_all_peds, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "world_get_all_objects", mruby__gtav__world_get_all_objects, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "_draw_text_many", mruby__gtav___draw_text_many, MRB_ARGS_REQ(14));
	mrb_define_class_method(mrb, module, "reset_mruby_next_tick!", mruby__gtav__reset_mruby_next_tick, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "set_game_window", mruby__gtav__set_game_window, MRB_ARGS_REQ(5));
	mrb_define_class_method(mrb, module, "set_console_window", mruby__gtav__set_console_window, MRB_ARGS_REQ(5));
	mrb_define_class_method(mrb, module, "is_syntax_valid?", mruby_is_syntax_valid, MRB_ARGS_REQ(1));

	mrb_define_class_method(mrb, module, "socket_init", mruby__gtav__socket_init, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "socket_listen", mruby__gtav__socket_listen, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "socket_accept", mruby__gtav__socket_accept, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "socket_read", mruby__gtav__socket_read, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "socket_write", mruby__gtav__socket_write, MRB_ARGS_REQ(2));
	mrb_define_class_method(mrb, module, "socket_close", mruby__gtav__socket_close, MRB_ARGS_REQ(1));

	mrb_define_class_method(mrb, module, "memory_base", mruby__gtav__memory_base, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "memory_base_size", mruby__gtav__memory_base_size, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "memory_read", mruby__gtav__memory_read, MRB_ARGS_REQ(2));
	mrb_define_class_method(mrb, module, "memory_write", mruby__gtav__memory_write, MRB_ARGS_REQ(2));
	mrb_define_class_method(mrb, module, "memory_protect", mruby__gtav__memory_protect, MRB_ARGS_REQ(3));

	mrb_define_class_method(mrb, module, "script_global_read", mruby__gtav__script_global_read, MRB_ARGS_REQ(1));
	mrb_define_class_method(mrb, module, "script_global_write", mruby__gtav__script_global_write, MRB_ARGS_REQ(2));
	mrb_define_class_method(mrb, module, "script_object_address", mruby__gtav__script_object_address, MRB_ARGS_REQ(1));

	mrb_define_class_method(mrb, module, "dir_glob", mruby__gtav__dir_glob, MRB_ARGS_REQ(3));

	mrb_define_class_method(mrb, module, "game_version", mruby__gtav__game_version, MRB_ARGS_NONE());
	mrb_define_class_method(mrb, module, "screen_bmp", mruby__gtav__screen_bmp, MRB_ARGS_NONE());


	fprintf(stdout, "loading bootstrap\n");
	mruby_load_relative("./mruby/bootstrap.rb");

	fprintf(stdout, "adding native functions\n");
	mruby_install_natives(mrb);

	//mrb_mruby_tiny_io_gem_init(mrb);
	mrb_init_io(mrb); mrb_gc_arena_restore(mrb, 0);
	mrb_init_file(mrb); mrb_gc_arena_restore(mrb, 0);
	mrb_init_file_test(mrb); mrb_gc_arena_restore(mrb, 0);
	mrb_mruby_pack_gem_init(mrb);

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
	if (mrb) {
		(void)mrb_funcall(mrb, mrb_obj_value(module), "on_shutdown", 0);
		// shut down mruby VM
		mrb_close(mrb);
	}
}





// script hook main loop

void main()
{	
	FILE *rfile;
	rfile = fopen("./mruby/enable-console", "r");
	if (rfile) {
		fclose(rfile);
		//SetStdOutToNewConsole();
	}

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
