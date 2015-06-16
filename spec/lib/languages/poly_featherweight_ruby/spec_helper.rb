require_relative '../../../spec_helper'
load_family 'poly_featherweight_ruby'

def tyobject(klass)
  TypedRb::Languages::PolyFeatherweightRuby::Types::TyObject.new(klass)
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
