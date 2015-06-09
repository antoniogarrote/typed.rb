require_relative './spec_helper'

describe TypedRb::Languages::PolyFeatherweightRuby::Types::TyObject do

  let(:ty_object) { TypedRb::Languages::PolyFeatherweightRuby::Types::TyObject.new(Object) }
  let(:ty_numeric) { TypedRb::Languages::PolyFeatherweightRuby::Types::TyObject.new(Numeric) }
  let(:ty_integer) { TypedRb::Languages::PolyFeatherweightRuby::Types::TyObject.new(Integer) }

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

    #expect(ty_numeric <= ty_numeric).to be_truthy
    #expect(ty_integer <= ty_integer).to be_truthy
    #expect(ty_object <= ty_object).to be_truthy

    expect([ty_numeric, ty_integer, ty_object].sort).to  eq([ty_integer, ty_numeric, ty_object])
  end

  it 'is possible to compare if two objects are compatible' do
    expect(ty_object.compatible?(ty_numeric, :gt)).to be_truthy
    expect(ty_object.compatible?(ty_numeric, :lt)).to be_falsey
    expect(ty_object.compatible?(ty_numeric, :lt)).to be_falsey
    expect(ty_object.compatible?(ty_numeric, :gt)).to be_truthy
  end
end