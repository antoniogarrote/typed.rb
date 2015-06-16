require_relative './spec_helper'

describe TypedRb::Languages::PolyFeatherweightRuby::Types::TyObject do
  let(:ty_object) { TypedRb::Languages::PolyFeatherweightRuby::Types::TyObject.new(Object) }
  let(:ty_numeric) { TypedRb::Languages::PolyFeatherweightRuby::Types::TyObject.new(Numeric) }
  let(:ty_integer) { TypedRb::Languages::PolyFeatherweightRuby::Types::TyObject.new(Integer) }
  let(:ty_string) { tyobject(String) }

  it 'is possible to compare TyObjects' do

    expect(ty_object > ty_numeric).to be_truthy
    expect(ty_numeric > ty_integer).to be_truthy
    expect(ty_object > ty_integer).to be_truthy

    expect(ty_object >= ty_numeric).to be_truthy
    expect(ty_object >= ty_object).to be_truthy
    expect(ty_numeric >= ty_integer).to be_truthy
    expect(ty_numeric >= ty_numeric).to be_truthy
    expect(ty_object >= ty_integer).to be_truthy
    expect(ty_object >= ty_object).to be_truthy

    expect(ty_numeric < ty_object).to be_truthy
    expect(ty_integer < ty_numeric).to be_truthy
    expect(ty_integer < ty_object).to be_truthy

    expect{ ty_string < ty_integer }.to raise_error TypedRb::Languages::PolyFeatherweightRuby::Types::UncomparableTypes
    expect{ ty_integer < ty_string }.to raise_error TypedRb::Languages::PolyFeatherweightRuby::Types::UncomparableTypes
    expect{ ty_string > ty_integer }.to raise_error TypedRb::Languages::PolyFeatherweightRuby::Types::UncomparableTypes
    expect{ ty_integer > ty_string }.to raise_error TypedRb::Languages::PolyFeatherweightRuby::Types::UncomparableTypes


    expect(ty_numeric <= ty_numeric).to be_truthy
    expect(ty_integer <= ty_integer).to be_truthy
    expect(ty_object <= ty_object).to be_truthy

    expect(ty_numeric >= ty_numeric).to be_truthy
    expect(ty_integer >= ty_integer).to be_truthy
    expect(ty_object >= ty_object).to be_truthy


    expect([ty_numeric, ty_integer, ty_object].sort).to  eq([ty_integer, ty_numeric, ty_object])
  end

  it 'is possible to compare if two objects are compatible' do
    expect(ty_object.compatible?(ty_numeric, :gt)).to be_truthy
    expect(ty_object.compatible?(ty_numeric, :lt)).to be_falsey
    expect(ty_object.compatible?(ty_numeric, :lt)).to be_falsey
    expect(ty_object.compatible?(ty_numeric, :gt)).to be_truthy
  end

  describe '#find_function_type' do
    before :each do
      ::BasicObject::TypeRegistry.registry.clear
    end

    it 'it can find methods in the base and super classes' do
      $TYPECHECK = true
      code = <<__END

         class A1
            ts 'A1#a / String -> unit'
            def a; puts 'a'; end
         end

         class B1 < A1
            ts 'B1#b / Numeric -> unit'
            def b; puts 'a'; end
         end
__END

      eval(code)
      ::BasicObject::TypeRegistry.normalize_types!

      ty_b = described_class.new(B1)

      method = ty_b.find_function_type(:a)
      expect(method.to_s).to eq('(String -> NilClass)')

      method = ty_b.find_function_type(:b)
      expect(method.to_s).to eq('(Numeric -> NilClass)')
    end
  end
end
