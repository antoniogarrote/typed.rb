require_relative '../spec_helper'


describe TypedRb::Languages::PolyFeatherweightRuby::Types::Polymorphism::Unification do
  it 'should be able to unify a simple constraint' do
    type_var = tyvariable('@a')
    integer = tyobject(Integer)
    type_var.compatible?(integer)

    unification = described_class.new(type_var.constraints)
    unification.run
    expect(type_var.bound).to eq(integer)
  end

  context 'with variable instance assignations' do
    it 'should be able to unify compatible types' do
      type_var = tyvariable('@a')
      integer = tyobject(Integer)
      numeric = tyobject(Numeric)
      # @a = Integer
      type_var.compatible?(integer, :gt)
      # @a = Numeric
      type_var.compatible?(numeric, :gt)

      unification = described_class.new(type_var.constraints)
      unification.run.bindings

      # @a = max(Integer, Numeric)
      expect(type_var.bound).to eq(numeric)
    end

    it 'should raise an exception on unificable types' do
      type_var = tyvariable('@a')
      integer = tyobject(Integer)
      string = tyobject(String)
      # @a = Integer
      type_var.compatible?(integer, :gt)
      # @a = Numeric
      type_var.compatible?(string, :gt)

      unification = described_class.new(type_var.constraints)
      unification.run.bindings

      # @a = max(Integer, Numeric)
      expect(type_var.bound.to_s).to eq('Object')
    end
  end
end
