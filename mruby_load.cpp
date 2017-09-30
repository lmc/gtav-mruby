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

mrb_value mruby_is_syntax_valid(mrb_state *mrb, mrb_value self) {
	char *code;
	size_t code_s;
	mrb_get_args(mrb, "s", &code, &code_s);
	mrbc_context *cxt = mrbc_context_new(mrb);
	mrbc_filename(mrb, cxt, "eval");
	cxt->capture_errors = true;
	mrb_parser_state *parser = mrb_parse_string(mrb, code, cxt);
	if (parser->nerr > 0) {
		mrbc_context_free(mrb, cxt);
		mrb_parser_free(parser);
		return mrb_false_value();
	}
	else {
		mrbc_context_free(mrb, cxt);
		mrb_parser_free(parser);
		return mrb_true_value();
	}
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
