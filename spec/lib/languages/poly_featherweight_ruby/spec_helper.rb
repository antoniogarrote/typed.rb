require_relative '../../../spec_helper'
load_family 'poly_featherweight_ruby'

def tyobject(klass)
  TypedRb::Languages::PolyFeatherweightRuby::Types::TyObject.new(klass)
end

def tyinteger
  TypedRb::Languages::PolyFeatherweightRuby::Types::TyObject.new(Integer)
end

def tyunit
  TypedRb::Languages::PolyFeatherweightRuby::Types::TyUnit.new
end

def tyboolean
  TypedRb::Languages::PolyFeatherweightRuby::Types::TyBoolean.new
end

def tyvariable(name)
  TypedRb::Languages::PolyFeatherweightRuby::Types::Polymorphism::TypeVariable.new(name)
end

def eval_with_ts(code)
  ::BasicObject::TypeRegistry.registry.clear
  $TYPECHECK = true
  eval(code)
  ::BasicObject::TypeRegistry.normalize_types!
end

def find_instance_variable_for(klass, variable, language)
  language.type_variables.detect{ |v| v.to_s =~ /#{klass}:#{variable}/ }
end

def expect_binding(language, klass, variable, type)
  var = find_instance_variable_for(klass, variable, language)
  expect(var.bound).to_not be_nil
  expect(var.bound.ruby_type).to be(type)
end
