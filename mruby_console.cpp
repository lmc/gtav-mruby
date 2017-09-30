// console helper

BOOL console_spawned = false;

void SetStdOutToNewConsole()
{
	if (console_spawned == false) {

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

		console_spawned = true;

		HWND window_game = FindWindow(NULL, "Grand Theft Auto V");
		SetWindowPos(window_game, NULL, 0, 0, 1920 + 4, 1080 + 25, 0);

		HWND window_console = GetConsoleWindow();
		SetWindowPos(window_console, NULL, 1920 - 5, 0, 650, 1080 + 25, 0);

	}
}


mrb_value mruby__gtav__spawn_console(mrb_state *mrb, mrb_value self) {
	mrb_int a0, a1, a2, a3, a4, a5, a6, a7, a8, a9;
	mrb_get_args(mrb, "iiiiiiiiii", &a0, &a1, &a2, &a3, &a4, &a5, &a6, &a7, &a8, &a9);

	//SetStdOutToNewConsole(a0, a1, a2, a3, a4, a5, a6, a7, a8, a9);

	if (console_spawned == false) {

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

		console_spawned = true;

		HWND window_game = FindWindow(NULL, "Grand Theft Auto V");
		SetWindowPos(window_game, NULL, a0, a1, a2, a3, 0);

		HWND window_console = GetConsoleWindow();
		SetWindowPos(window_console, NULL, a5, a6, a7, a8, 0);
	}

	return mrb_nil_value();
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
