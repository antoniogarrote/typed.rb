require_relative '../../../spec_helper'
load_family 'poly_featherweight_ruby'

def tyobject(klass)
  TypedRb::Languages::PolyFeatherweightRuby::Types::TyObject.new(klass)
end

def tyvariable(name)
  TypedRb::Languages::PolyFeatherweightRuby::Types::Polymorphism::TypeVariable.new(name)
end