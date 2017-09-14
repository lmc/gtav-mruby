
NATIVES_H = "../../inc/natives.h"

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
    # puts current_namespace
    # puts name
    # puts natives[current_namespace][name].inspect
  end
end


def return_for_type(type)
  case type
  when "void"
    "return mrb_nil_value();"
  when "BOOL"
    "return mrb_bool_value(r0);"
  when "int"
    "return mrb_fixnum_value(r0);"
  when "float"
    "return mrb_float_value(mrb,r0);"
  when "Player" # player can be 0, so exclude this from the nil check
<<-CPP
mrb_value rret = mrb_obj_new(mrb, mrb_class_get_under(mrb, mrb_module_get(mrb, "GTAV"), "#{type}"), 0, NULL);
  (void)mrb_funcall(mrb, rret, "__load", 1, mrb_fixnum_value(r0));
  return rret;
CPP
  when "Ped", "Entity", "Vehicle"
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
  (void)mrb_funcall(mrb, rvector3, "__load", 3, mrb_float_value(mrb, cvector3.x), mrb_float_value(mrb, cvector3.y), mrb_float_value(mrb, cvector3.z));
  return rvector3;
CPP
  else
    raise "unknown type #{type}"
  end
end

def cassigns_for_type(type)
  case type
  when "void"
    ""
  when "Player"
    "Player r0 = "
  when "Ped"
    "Ped r0 = "
  when "Vector3"
    "Vector3 cvector3 = "
  when "Vehicle"
    "Vehicle r0 = "
  when "Entity"
    "Entity r0 = "
  when "float"
    "mrb_float r0 = "
  when "int"
    "mrb_int r0 = "
  when "BOOL"
    "mrb_bool r0 = "
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
    mrb_type, mrb_char = mrb_type_and_char(arg)
    defs << "#{mrb_type} a#{i};"
    chars << mrb_char
    cargs << "a#{i}"
    crargs << "&a#{i}"
  end
  [defs.join("\n  "),chars.join(""),cargs.join(", "),crargs.join(", ")]
end

def mrb_type_and_char(arg)
  case arg[:type]
  when "float"
    ["mrb_float","f"]
  else
    ["mrb_int","i"]
  end
end


module_defines = []
function_bodies = []
mrb_defines = []

natives.each_pair do |mname,namespace|
  module_defines << "struct RClass *module_#{mname.downcase} = mrb_define_module(mrb, \"#{mname}\");"
  namespace.each_pair do |fname,definition|
    # next unless ["PED","ENTITY","GRAPHICS","VEHICLE","PLAYER"].include?( mname )
    next unless ["void","Player","Ped","Vector3","Vehicle","Entity","int","float","BOOL"].include?( definition[:return_type] )
    # next unless [0,4].include?( definition[:arguments].size )
    next unless definition[:arguments].all?{|a| ["Entity","float","BOOL","int","Ped","Player","Vehicle","Entity","Any","Object","Hash"].include?(a[:type]) }
    # puts [mname,fname,definition].inspect

    cname = "mruby__#{mname}__#{fname}"
    mrb_args_def = "MRB_ARGS_NONE()"
    mrb_get_args = nil
    mrb_value_defs, mrb_chars, cargs, crargs = mrb_value_defines(definition[:arguments])
    if definition[:arguments].size > 0
      mrb_get_args = "mrb_get_args(mrb,\"#{mrb_chars}\",#{crargs});"
      mrb_args_def = "MRB_ARGS_REQ(#{definition[:arguments].size})"
    end

    mrb_defines << "mrb_define_class_method(mrb, module_#{mname.downcase}, \"#{fname}\", #{cname}, #{mrb_args_def});"
    function_bodies << <<-CPP
mrb_value #{cname}(mrb_state *mrb, mrb_value self) {
  #{mrb_value_defs}
  #{mrb_get_args if mrb_get_args}
  #{cassigns_for_type(definition[:return_type])}#{mname}::#{fname}(#{cargs});
  #{return_for_type(definition[:return_type]).chomp}
}
CPP
  end
end


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


#{function_bodies.join("\n\n\n")}


void mruby_install_natives(mrb_state *mrb) {
  #{module_defines.join("\n  ")}

  #{mrb_defines.join("\n  ")}
}

CPP

print template


puts "// generated #{function_bodies.size} natives"