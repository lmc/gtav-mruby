
NATIVES_H = "../../inc/natives.h"

WITH_TICK_CHECK = true

natives = Hash.new{|h,k| h[k] = {}}
current_namespace = nil

File.open(NATIVES_H,"r") do |f|
  f.each_line do |line|
    line.strip!
    if matches = line.match(/\Anamespace (\w+)/)
      current_namespace = matches[1]
    end
    next if !line.match(/\Astatic /)

    _, return_type, name, args = *line.match(%r{static ([A-Za-z0-9*]+) (\w+)\(([^\)]*)\)}i)
    args = args.split(/, ?/).map do |arg|
      {
        type: arg.split(" ")[0],
        name: arg.split(" ")[1],
      }
    end

    natives[current_namespace][name] = {
      return_type: return_type,
      arguments: args
    }
  end
end


def return_for_type(type)
  case type
  when "void"
    "return mrb_nil_value();"
  when "BOOL"
    "return mrb_bool_value(r0);"
  when "int", "Any"
    "return mrb_fixnum_value(r0);"
  when "float"
    "return mrb_float_value(mrb,r0);"
  when "Player" # player can be 0, so exclude this from the nil check
<<-CPP
mrb_value rret = mrb_obj_new(mrb, mrb_class_get_under(mrb, mrb_module_get(mrb, "GTAV"), "#{type}"), 0, NULL);
  (void)mrb_funcall(mrb, rret, "__load", 1, mrb_fixnum_value(r0));
  return rret;
CPP
  when "Ped", "Entity", "Vehicle", "Hash", "Blip", "Cam","ScrHandle","Pickup"
    <<-CPP
if(r0 == 0) {
    return mrb_nil_value();
  } else {
    mrb_value rret = mrb_obj_new(mrb, mrb_class_get_under(mrb, mrb_module_get(mrb, "GTAV"), "#{type}"), 0, NULL);
    (void)mrb_funcall(mrb, rret, "__load", 1, mrb_fixnum_value(r0));
    return rret;
  }
CPP
  when "Vector3"
    <<-CPP
mrb_value rvector3 = mrb_obj_new(mrb, mrb_class_get_under(mrb, mrb_module_get(mrb, "GTAV"), "Vector3"), 0, NULL);
  (void)mrb_funcall(mrb, rvector3, "__load", 3, mrb_float_value(mrb, r0.x), mrb_float_value(mrb, r0.y), mrb_float_value(mrb, r0.z));
  return rvector3;
CPP
  when "char*"
    <<-CPP
return mrb_str_new_cstr(mrb,cstr);
CPP
  else
    raise "unknown type #{type}"
  end
end

def cassigns_for_type(type)
  case type
  when "void"
    ""
  when "Any", "Vector3", "Player", "Ped", "Entity", "Vehicle", "Hash", "Blip", "Cam","ScrHandle","Pickup"
    "#{type} r0 = "
  when "float"
    "mrb_float r0 = "
  when "int"
    "mrb_int r0 = "
  when "BOOL"
    "mrb_bool r0 = "
  when "char*"
    "char* cstr = "
  else
    raise "unknown type #{type}"
  end
end

def mrb_value_defines(arguments)
  defs = []
  chars = []
  cargs = []
  crargs = []
  arguments.each_with_index do |arg,i|
    mrb_types, mrb_char, n_cargs, n_crargs = mrb_type_and_char(arg,i)
    defs += mrb_types
    chars << mrb_char
    cargs += n_cargs
    crargs += n_crargs
  end
  [defs.join("\n  "),chars.join(""),cargs.join(", "),crargs.join(", ")]
end

def mrb_type_and_char(arg,i)
  case arg[:type]
  when "char*"
    [["char* a#{i};","int a#{i}_size;"],"s",["a#{i}"],["&a#{i}, &a#{i}_size"]]
  when "BOOL"
    [["mrb_bool a#{i};"],"b",["a#{i}"],["&a#{i}"]]
  when "float"
    [["mrb_float a#{i};"],"f",["a#{i}"],["&a#{i}"]]
  when "Vehicle*","Ped*","Entity*","Any*"
    [["#{arg[:type].gsub("*","")} a#{i};"],"i",["&a#{i}"],["&a#{i}"]]
  else
    [["mrb_int a#{i};"],"i",["a#{i}"],["&a#{i}"]]
  end
end

def tick_check
  "\n  if(call_limit_enabled && (call_limit-- < 0)) mrb_raise(mrb, mrb_class_get(mrb,\"CallLimitExceeded\"), \"\");"
end


module_defines = []
$function_bodies = []
$mrb_defines = []

def define_native(mname,fname,argc,body)
  cname = "mruby__#{mname}__#{fname}"
  mrb_args_def = "MRB_ARGS_NONE()"
  mrb_args_def = "MRB_ARGS_REQ(#{argc})" if argc > 0
  $mrb_defines << "mrb_define_class_method(mrb, module_#{mname.downcase}, \"#{fname}\", #{cname}, #{mrb_args_def});"
  $function_bodies << <<-CPP
  mrb_value #{cname}(mrb_state *mrb, mrb_value self) {#{WITH_TICK_CHECK ? tick_check : ""}
    #{body}
  }
CPP
end

natives.each_pair do |mname,namespace|
  module_defines << "struct RClass *module_#{mname.downcase} = mrb_define_module(mrb, \"#{mname}\");"
  namespace.each_pair do |fname,definition|
    gen = true
    # next unless ["PED","ENTITY","GRAPHICS","VEHICLE","PLAYER"].include?( mname )
    gen = false unless ["void","Player","Ped","Vector3","Vehicle","Entity","int","float","BOOL","Hash","Any","Blip","Cam","ScrHandle","Pickup","char*"].include?( definition[:return_type] )
    # next unless [0,4].include?( definition[:arguments].size )
    gen = false unless definition[:arguments].all?{|a| ["Entity","float","BOOL","int","Ped","Player","Vehicle","Entity","Any","Object","Hash","Blip","Cam","ScrHandle","Pickup","char*","Vehicle*","Ped*","Entity*","Any*"].include?(a[:type]) }
    gen = false unless definition[:arguments].each_with_index.all?{|a,i| ["Vehicle*","Ped*","Entity*","Any*"].include?(a[:type]) ? i == 0 : true }
    # puts [mname,fname,definition].inspect

    if !gen
      puts "// not generating #{mname}::#{fname} - #{definition.inspect}"
      next
    end

    cname = "mruby__#{mname}__#{fname}"
    mrb_args_def = "MRB_ARGS_NONE()"
    mrb_get_args = nil
    mrb_value_defs, mrb_chars, cargs, crargs = mrb_value_defines(definition[:arguments])
    if definition[:arguments].size > 0
      mrb_get_args = "mrb_get_args(mrb,\"#{mrb_chars}\",#{crargs});"
      mrb_args_def = "MRB_ARGS_REQ(#{definition[:arguments].size})"
    end

    $mrb_defines << "mrb_define_class_method(mrb, module_#{mname.downcase}, \"#{fname}\", #{cname}, #{mrb_args_def});"
    $function_bodies << <<-CPP
mrb_value #{cname}(mrb_state *mrb, mrb_value self) {#{WITH_TICK_CHECK ? tick_check : ""}#{"\n  "+mrb_value_defs+"\n" if mrb_value_defs.size > 0}#{"  "+mrb_get_args+"" if mrb_get_args}
  #{cassigns_for_type(definition[:return_type])}#{mname}::#{fname}(#{cargs});
  #{return_for_type(definition[:return_type]).chomp}
}
CPP
  end
end

define_native("GRAPHICS","_WORLD3D_TO_SCREEN2D",3,<<-CPP)
  mrb_float a0;
  mrb_float a1;
  mrb_float a2;
  mrb_get_args(mrb,"fff",&a0,&a1,&a2);

  float r0;
  float r1;

  GRAPHICS::_WORLD3D_TO_SCREEN2D(a0,a1,a2,&r0,&r1);

  if(r0 < 0.0 && r1 < 0.0) {
    return mrb_nil_value();
  } else {
    mrb_value rarray = mrb_ary_new_capa(mrb,2);
    mrb_ary_set(mrb,rarray,0,mrb_float_value(mrb,r0));
    mrb_ary_set(mrb,rarray,1,mrb_float_value(mrb,r1));
    return rarray;
  }
CPP

template = <<-CPP
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

static int call_limit_enabled = 0;
static int call_limit = 1000;

#{$function_bodies.join("\n")}


void mruby_install_natives(mrb_state *mrb) {
  #{module_defines.join("\n  ")}

  #{$mrb_defines.join("\n  ")}
}

mrb_value mruby__gtav__set_call_limit(mrb_state *mrb, mrb_value self) {
  mrb_int a0;
  mrb_get_args(mrb,"i",&a0);
  if(a0 == -1){
    call_limit_enabled = 0;
  } else {
    call_limit_enabled = 1;
  }
  call_limit = a0;
  return mrb_nil_value();
}

mrb_value mruby__gtav__get_call_limit(mrb_state *mrb, mrb_value self) {
  return mrb_fixnum_value(call_limit);
}

CPP

print template

generated = $function_bodies.size
total = natives.values.map(&:size).inject(0){|a,i| a + i}
puts "// generated #{generated} out of #{total} native functions (#{total - generated} ungenerated)"