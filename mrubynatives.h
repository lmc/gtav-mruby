/*
	THIS FILE IS A PART OF GTA V SCRIPT HOOK SDK
				http://dev-c.com
			(C) Alexander Blade 2015
*/

#pragma once

void mruby_install_natives(mrb_state *mrb);

mrb_value mruby__gtav__set_call_limit(mrb_state *mrb, mrb_value self);
mrb_value mruby__gtav__get_call_limit(mrb_state *mrb, mrb_value self);


