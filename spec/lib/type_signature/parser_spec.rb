require_relative '../../spec_helper'

describe TypedRb::TypeSignature::Parser do

  it 'parses a unit type' do
    result = described_class.parse('unit')
    expect(result).to be == :unit
  end

  it 'parses an atomic type' do
    result = described_class.parse('Bool')
    expect(result).to be =='Bool'
  end

  it 'parses a function type' do
    result = described_class.parse('Bool => Int')
    expect(result).to be == ['Bool', 'Int']
  end

  it 'parses a complex type' do
    result = described_class.parse('Bool => Int    => Bool')
    expect(result).to be == ['Bool', ['Int', 'Bool']]
  end

  it 'parses a complex type using unit' do
    result = described_class.parse('Bool => Int => unit')
    expect(result).to be == ['Bool', ['Int', :unit]]
  end

  it 'parses a types with parentheses' do
    result = described_class.parse('(Bool => Int) => Bool')
    expect(result).to be == [['Bool', 'Int'], 'Bool']
  end

  it 'parses a types with parentheses in the return type' do
    result = described_class.parse('Bool => (Int => Bool)')
    expect(result).to be == ['Bool', ['Int', 'Bool']]
  end

  it 'parses a types with parentheses in the complex return type' do
    result = described_class.parse('Bool => (Int => (Bool => Int))')
    expect(result).to be == ['Bool', ['Int', ['Bool', 'Int']]]
  end

  it 'parses a types with complex parentheses' do
    result = described_class.parse('(Bool => Bool) => (Bool => Int)')
    expect(result).to be == [['Bool', 'Bool'], ['Bool', 'Int']]
  end

  it 'parses a types with complex compound parentheses' do
    result = described_class.parse('((Bool => Bool) => (Bool => Int)) => (Bool => Int)')
    expect(result).to be == [[['Bool','Bool'], ['Bool', 'Int']], ['Bool', 'Int']]
  end

  it 'parses unbalanced type expressions' do
    result = described_class.parse('Bool => Int => (Bool => Int) => Int')
    expect(result).to be == ['Bool',['Int', [['Bool','Int'], 'Int']]]
  end
end