
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
  when "Ped", "Entity", "Vehicle", "Hash", "Blip", "Cam","ScrHandle","Pickup", "Object"
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
  when "Any", "Vector3", "Player", "Ped", "Entity", "Vehicle", "Hash", "Blip", "Cam","ScrHandle","Pickup", "Object"
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
  case arg[:type].to_s
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

$defined_functions = {}
module_defines = []
$function_bodies = []
$mrb_defines = []

def define_native(mname,fname,argc,body)
  cname = "mruby__#{mname}__#{fname}"
  mrb_args_def = "MRB_ARGS_NONE()"
  mrb_args_def = "MRB_ARGS_REQ(#{argc})" if argc > 0
  $defined_functions["#{mname}::#{fname}"] = true
  $mrb_defines << "mrb_define_class_method(mrb, module_#{mname.downcase}, \"#{fname}\", #{cname}, #{mrb_args_def});"
  $function_bodies << <<-CPP
  mrb_value #{cname}(mrb_state *mrb, mrb_value self) {#{WITH_TICK_CHECK ? tick_check : ""}
    #{body}
  }
CPP
end

def define_native_multireturn(mname,fname,in_types,out_types,assign,cargs,assign_return,return_nil_if = nil)
  cname = "mruby__#{mname}__#{fname}"
  mrb_args_def = "MRB_ARGS_NONE()"
  mrb_args_def = "MRB_ARGS_REQ(#{in_types.size})" if in_types.size > 0

  in_type_chars = ""
  in_type_vars = []
  in_type_assigns = in_types.each_with_index.map{|t,i|
    tt = mrb_type_and_char({type: t},i)
    in_type_vars << tt[3].join(",")
    in_type_chars << tt[1]
    tt[0].join("\n  ")
  }.join("\n  ")

  out_type_defs = Array(out_types).each_with_index.map{|t,i|
    case t
    when :int
      "int r#{i};"
    when :float
      "float r#{i};"
    when :char
      "char* r#{i};"
    when :BOOL
      "BOOL r#{i};"
    else
      "#{t} r#{i};"
    end
  }.join("\n  ")

  rarray_i = 0
  if assign
    assign = "#{assign} r = "
  end
  if assign_return
    assign_return = "mrb_ary_set(mrb,rarray,#{rarray_i},#{include_assign});\n  "
  end
  if out_types.is_a?(Array)
    rarray_sets = out_types.each_with_index.map {|t,i|
      s = case t
      when :int
        "mrb_ary_set(mrb,rarray,#{rarray_i},mrb_fixnum_value(r#{i}));"
      when :float
        "mrb_ary_set(mrb,rarray,#{rarray_i},mrb_float_value(mrb,r#{i}));"
      when :BOOL
        "mrb_ary_set(mrb,rarray,#{rarray_i},mrb_bool_value(r#{i}));"
      when :Vector3
        s = []
        s << "mrb_value r#{i}v = mrb_obj_new(mrb, mrb_class_get_under(mrb, mrb_module_get(mrb, \"GTAV\"), \"Vector3\"), 0, NULL);"
        s << "(void)mrb_funcall(mrb, r#{i}v, \"__load\", 3, mrb_float_value(mrb, r#{i}.x), mrb_float_value(mrb, r#{i}.y), mrb_float_value(mrb, r#{i}.z));"
        s << "mrb_ary_set(mrb,rarray,#{rarray_i},r#{i}v);"
        # puts s
        # s << "mrb_ary_set(mrb,rarray,#{rarray_i},mrb_float_value(mrb,r#{i}.x));"
        # rarray_i += 1
        # s << "mrb_ary_set(mrb,rarray,#{rarray_i},mrb_float_value(mrb,r#{i}.y));"
        # rarray_i += 1
        # s << "mrb_ary_set(mrb,rarray,#{rarray_i},mrb_float_value(mrb,r#{i}.z));"
        s.join("\n  ")
      else
        "mrb_ary_set(mrb,rarray,#{rarray_i},mrb_fixnum_value(r#{i}));"
      end
      rarray_i += 1
      s
    }.join("\n  ")
    return_statement = <<-CPP
  mrb_value rarray = mrb_ary_new_capa(mrb,#{rarray_i});
  #{assign_return}
  #{rarray_sets}
  return rarray;
CPP
  else
    return_statement = case out_types
    when :int
      "return mrb_fixnum_value(r0);"
    when :float
      "return mrb_float_value(mrb,r0);"
    when :BOOL
      "return mrb_bool_value(r0);"
    when :Vector3
    <<-CPP
  mrb_value rret = mrb_obj_new(mrb, mrb_class_get_under(mrb, mrb_module_get(mrb, "GTAV"), "#{out_types}"), 0, NULL);
  (void)mrb_funcall(mrb, rret, "__load", 3, mrb_float_value(mrb,r0.x), mrb_float_value(mrb,r0.y), mrb_float_value(mrb,r0.z));
  return rret;
CPP
    else
      assign_return = nil
      <<-CPP
  mrb_value rret = mrb_obj_new(mrb, mrb_class_get_under(mrb, mrb_module_get(mrb, "GTAV"), "#{out_types}"), 0, NULL);
  (void)mrb_funcall(mrb, rret, "__load", 1, mrb_fixnum_value(r0));
  return rret;
CPP
    end
  end

  if return_nil_if
    return_statement = <<-CPP
  if(#{return_nil_if}){
    return mrb_nil_value();
  } else {
    #{return_statement}
  }
CPP
  end

  if return_nil_if === true
    return_statement = "return mrb_nil_value();"
  end

  mrb_get_args = "mrb_get_args(mrb,\"#{in_type_chars}\",#{in_type_vars.join(",")});"
  mrb_get_args = "" if in_types.size == 0

  $defined_functions["#{mname}::#{fname}"] = true
  $mrb_defines << "mrb_define_class_method(mrb, module_#{mname.downcase}, \"#{fname}\", #{cname}, #{mrb_args_def});"
  $function_bodies << <<-CPP
  mrb_value #{cname}(mrb_state *mrb, mrb_value self) {#{WITH_TICK_CHECK ? tick_check : ""}
  #{in_type_assigns}
  #{mrb_get_args}
  #{out_type_defs}
  #{assign}#{mname}::#{fname}(#{cargs});
  #{return_statement}
}
CPP
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

# n(mname,fname,in_types,out_types,assign,cargs)
define_native_multireturn("PLAYER","GET_PLAYER_RGB_COLOUR",[:Player],[:int,:int,:int],nil,"a0,&r0,&r1,&r2",nil)
define_native_multireturn("PLAYER","GET_PLAYER_TARGET_ENTITY",[:Player],:Entity,"BOOL","a0,&r0",nil,"!r")
define_native_multireturn("PLAYER","GET_ENTITY_PLAYER_IS_FREE_AIMING_AT",[:Player],:Entity,"BOOL","a0,&r0",nil,"!r")
define_native_multireturn("PLAYER","GET_PLAYER_PARACHUTE_TINT_INDEX",[:Player],:int,nil,"a0,&r0",nil,"r0 == -1")
define_native_multireturn("PLAYER","GET_PLAYER_RESERVE_PARACHUTE_TINT_INDEX",[:Player],:int,nil,"a0,&r0",nil,"r0 == -1")
define_native_multireturn("PLAYER","GET_PLAYER_PARACHUTE_PACK_TINT_INDEX",[:Player],:int,nil,"a0,&r0",nil,"r0 == -1")
define_native_multireturn("PLAYER","GET_PLAYER_PARACHUTE_SMOKE_TRAIL_COLOR",[:Player],[:int,:int,:int],nil,"a0,&r0,&r1,&r2",nil,nil)

define_native_multireturn("ENTITY","GET_ENTITY_MATRIX",[:Entity],[:Any,:Any,:Vector3,:Vector3],nil,"a0,&r0,&r1,&r2,&r3",nil,nil)
define_native_multireturn("ENTITY","GET_ENTITY_QUATERNION",[:Entity],[:float,:float,:float,:float],nil,"a0,&r0,&r1,&r2,&r3",nil,nil)

define_native_multireturn("ENTITY","SET_OBJECT_AS_NO_LONGER_NEEDED",[:Entity],[],nil,"(Object*) &a0",nil,true)
define_native_multireturn("OBJECT","DELETE_OBJECT",[:Entity],[],nil,"(Object*) &a0",nil,true)

define_native_multireturn("VEHICLE","GET_VEHICLE_CUSTOM_PRIMARY_COLOUR",[:Vehicle],[:int,:int,:int],nil,"a0,&r0,&r1,&r2",nil,nil)
define_native_multireturn("VEHICLE","GET_VEHICLE_CUSTOM_SECONDARY_COLOUR",[:Vehicle],[:int,:int,:int],nil,"a0,&r0,&r1,&r2",nil,nil)
define_native_multireturn("VEHICLE","GET_VEHICLE_COLOURS",[:Vehicle],[:int,:int],nil,"a0,&r0,&r1",nil,nil)
define_native_multireturn("VEHICLE","GET_VEHICLE_LIGHTS_STATE",[:Vehicle],[:int,:int],nil,"a0,&r0,&r1",nil,nil)
define_native_multireturn("VEHICLE","GET_RANDOM_VEHICLE_MODEL_IN_MEMORY",[:BOOL],[:Hash,:int],nil,"a0,&r0,&r1",nil,nil)
define_native_multireturn("VEHICLE","GET_VEHICLE_EXTRA_COLOURS",[:Vehicle],[:int,:int],nil,"a0,&r0,&r1",nil,nil)
define_native_multireturn("VEHICLE","GET_VEHICLE_TRAILER_VEHICLE",[:Vehicle],:Vehicle,"BOOL","a0,&r0",nil,"!r")
define_native_multireturn("VEHICLE","GET_VEHICLE_MOD_COLOR_1",[:Vehicle],[:int,:int,:int],nil,"a0,&r0,&r1,&r2",nil,nil)
define_native_multireturn("VEHICLE","GET_VEHICLE_MOD_COLOR_2",[:Vehicle],[:int,:int],nil,"a0,&r0,&r1",nil,nil)
define_native_multireturn("VEHICLE","GET_VEHICLE_TYRE_SMOKE_COLOR",[:Vehicle],[:int,:int,:int],nil,"a0,&r0,&r1,&r2",nil,nil)
define_native_multireturn("VEHICLE","GET_VEHICLE_COLOR",[:Vehicle],[:int,:int,:int],nil,"a0,&r0,&r1,&r2",nil,nil)
define_native_multireturn("VEHICLE","_GET_VEHICLE_NEON_LIGHTS_COLOUR",[:Vehicle],[:int,:int,:int],nil,"a0,&r0,&r1,&r2",nil,nil)
define_native_multireturn("VEHICLE","_GET_VEHICLE_OWNER",[:Vehicle],:Entity,"BOOL","a0,&r0",nil,"!r")

define_native_multireturn("GRAPHICS","GET_SCREEN_RESOLUTION",[],[:int,:int],nil,"&r0,&r1",nil,nil)
define_native_multireturn("GRAPHICS","_GET_SCREEN_ACTIVE_RESOLUTION",[],[:int,:int],nil,"&r0,&r1",nil,nil)

define_native_multireturn("GAMEPLAY","GET_MODEL_DIMENSIONS",[:Hash],[:Vector3,:Vector3],nil,"a0,&r0,&r1",nil,nil)
define_native_multireturn("GAMEPLAY","GET_GROUND_Z_FOR_3D_COORD",[:float,:float,:float,:BOOL],:float,nil,"a0,a1,a2,&r0,a3",nil,nil)

define_native_multireturn("WEAPON","GET_CURRENT_PED_WEAPON",[:Ped,:BOOL],:Hash,"BOOL","a0,&r0,a1",nil,"!r")
define_native_multireturn("WEAPON","GET_CURRENT_PED_VEHICLE_WEAPON",[:Ped],:Hash,"BOOL","a0,&r0",nil,"!r")
define_native_multireturn("WEAPON","GET_AMMO_IN_CLIP",[:Ped,:Hash],:int,"BOOL","a0,a1,&r0",nil,"!r")
define_native_multireturn("WEAPON","GET_MAX_AMMO",[:Ped,:Hash],:int,"BOOL","a0,a1,&r0",nil,"!r")
define_native_multireturn("WEAPON","GET_PED_LAST_WEAPON_IMPACT_COORD",[:Ped],:Vector3,"BOOL","a0,&r0",nil,"!r")

natives.each_pair do |mname,namespace|
  module_defines << "struct RClass *module_#{mname.downcase} = mrb_define_module(mrb, \"#{mname}\");"
  namespace.each_pair do |fname,definition|
    gen = true
    # next unless ["PED","ENTITY","GRAPHICS","VEHICLE","PLAYER"].include?( mname )
    # gen = false unless ["void","Player","Ped","Vector3","Vehicle","Entity","int","float","BOOL","Hash","Any","Blip","Cam","ScrHandle","Pickup","char*","Object"].include?( definition[:return_type] )
    # next unless [0,4].include?( definition[:arguments].size )
    gen = false if ["Any*"].include?( definition[:return_type] )
    gen = false unless definition[:arguments].all?{|a| ["Entity","float","BOOL","int","Ped","Player","Vehicle","Entity","Any","Object","Hash","Blip","Cam","ScrHandle","Pickup","char*","Vehicle*","Ped*","Entity*","Any*"].include?(a[:type]) }
    gen = false unless definition[:arguments].each_with_index.all?{|a,i| ["Vehicle*","Ped*","Entity*","Any*"].include?(a[:type]) ? i == 0 : true }
    # puts [mname,fname,definition].inspect

    if !gen && !$defined_functions["#{mname}::#{fname}"]
      puts "// not generating #{mname}::#{fname} - #{definition.inspect}"
      next
    end

    if $defined_functions["#{mname}::#{fname}"]
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

# define_native("PLAYER","GET_PLAYER_RGB_COLOUR",1,<<-CPP)
#   mrb_int a0;
#   mrb_get_args(mrb,"i",&a0);

#   int r0;
#   int r1;
#   int r2;

#   PLAYER::GET_PLAYER_RGB_COLOUR(a0,&r0,&r1,&r2);

#   mrb_value rarray = mrb_ary_new_capa(mrb,3);
#   mrb_ary_set(mrb,rarray,0,mrb_fixnum_value(r0));
#   mrb_ary_set(mrb,rarray,1,mrb_fixnum_value(r1));
#   mrb_ary_set(mrb,rarray,1,mrb_fixnum_value(r2));
#   return rarray;
# CPP


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