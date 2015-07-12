require_relative '../../spec_helper'
require_relative '../../../lib/type_signature/parser'

describe TypedRb::TypeSignature::Parser do

  it 'parses a unit type' do
    result = described_class.parse('unit')
    expect(result).to eq(:unit)
  end

  it 'parses an atomic type' do
    result = described_class.parse('Bool')
    expect(result).to eq('Bool')
  end

  it 'parses an atomic type' do
    result = described_class.parse('Bool...')
    expect(result).to eq({:type       => 'Array',
                          :parameters =>  ['Bool'],
                          :kind       => :rest})
  end

  it 'parses a function type' do
    result = described_class.parse('Bool -> Int')
    expect(result).to eq(['Bool', 'Int'])
  end

  it 'parses applied type parameters in signatures' do
    result = described_class.parse('Bool... -> Array[Bool]')
    expect(result[0]).to eq({:type       => 'Array',
                             :parameters =>  ['Bool'],
                             :kind       => :rest})
    expect(result[1]).to eq({:type       => 'Array',
                             :parameters =>  [{:type=>"Bool", :bound=>"BasicObject", :kind=>:type_var}],
                             :kind       => :generic_type})
  end

  it 'parses a complex type' do
    result = described_class.parse('Bool -> Int    -> Bool')
    expect(result).to eq(['Bool', 'Int', 'Bool'])
  end

  it 'parses a complex type using unit' do
    result = described_class.parse('Bool -> Int -> unit')
    expect(result).to eq(['Bool', 'Int', :unit])
  end

  it 'parses a types with parentheses' do
    result = described_class.parse('(Bool -> Int) -> Bool')
    expect(result).to eq([['Bool', 'Int'], 'Bool'])
  end

  it 'parses a types with parentheses in the return type' do
    result = described_class.parse('Bool -> (Int -> Bool)')
    expect(result).to eq(['Bool', ['Int', 'Bool']])
  end

  it 'parses a types with parentheses in the complex return type' do
    result = described_class.parse('Bool -> (Int -> (Bool -> Int))')
    expect(result).to eq(['Bool', ['Int', ['Bool', 'Int']]])
  end

  it 'parses a types with complex parentheses' do
    result = described_class.parse('(Bool -> Bool) -> (Bool -> Int)')
    expect(result).to eq([['Bool', 'Bool'], ['Bool', 'Int']])
  end

  it 'parses a types with complex parentheses' do
    result = described_class.parse('(Bool -> Bool) -> (Bool -> Int) -> (Int -> Int)')
    expect(result).to eq([['Bool', 'Bool'], ['Bool', 'Int'], ['Int', 'Int']])
  end

  it 'parses a types with complex compound parentheses' do
    result = described_class.parse('((Bool -> Bool) -> (Bool -> Int)) -> (Bool -> Int)')
    expect(result).to eq([[['Bool','Bool'], ['Bool', 'Int']], ['Bool', 'Int']])
  end

  it 'parses unbalanced type expressions' do
    result = described_class.parse('Bool -> Int -> (Bool -> Int) -> Int')
    expect(result).to eq(['Bool','Int', ['Bool','Int'], 'Int'])
  end

  it 'parses unbalanced type expressions with just return types' do
    result = described_class.parse('Bool -> Int -> (-> Int) -> Int')
    expect(result).to eq(['Bool','Int', ['Int'], 'Int'])
  end

  it 'parses expressions with only return type' do
    result = described_class.parse(' -> Int')
    expect(result).to eq(['Int'])
  end

  it 'parses type variables' do
    result = described_class.parse('[X]')
    expect(result).to eq({:type => 'X', :bound => 'BasicObject', :kind => :type_var })
  end

  it 'parses bound type variables' do
    result = described_class.parse('[X < Integer]')
    expect(result).to eq({:type => 'X', :bound => 'Integer', :kind => :type_var })
  end

  it 'parses return type variables' do
    result = described_class.parse(' -> [X]')
    expect(result).to eq([{:type => 'X', :bound => 'BasicObject', :kind => :type_var }])
  end

  it 'parses type variables in both sides' do
    result = described_class.parse('[X<String] -> [Y]')
    expect(result).to eq([{:type => 'X', :bound => 'String', :kind => :type_var },
                          {:type => 'Y', :bound => 'BasicObject', :kind => :type_var }])
  end

  it 'parses type variables in complex expressions' do
    result = described_class.parse('[X] -> ([Y] -> Integer)')
    expect(result).to eq([{:type => 'X', :bound => 'BasicObject', :kind => :type_var },
                          [{:type => 'Y', :bound => 'BasicObject', :kind => :type_var },
                           'Integer']])
  end

  it 'parses a block' do
    result = described_class.parse('Int -> unit -> &(String -> Integer)')
    expect(result).to eq(['Int', :unit, {:block => ['String', 'Integer'], :kind => :block_arg}])
  end

  it 'parses parametric types' do
    result = described_class.parse('Array[X] -> [X]')
    expect(result).to eq([{:type       => "Array",
                           :parameters => [{:type => "X", :bound => "BasicObject", :kind => :type_var}],
                           :kind       => :generic_type},
                          {:type => "X",
                           :bound => "BasicObject",
                           :kind => :type_var}])
  end

  it 'parses parametric types with multiple var types' do
    result = described_class.parse('Int -> (Bool -> Array[X][Y][Z])')
    expect(result).to eq(["Int", ["Bool", {:type       => "Array",
                                           :parameters => [{:type => "X", :bound => "BasicObject", :kind => :type_var},
                                                           {:type => "Y", :bound => "BasicObject", :kind => :type_var},
                                                           {:type => "Z", :bound => "BasicObject", :kind => :type_var}],
                                           :kind       => :generic_type}]])
  end

  it 'parses parametric types with bounds' do
    result = described_class.parse('Array[X<Int] -> Hash[T<String][U<Object]')
    expect(result).to eq([{:type       => "Array",
                           :parameters => [{:type => "X", :bound => "Int", :kind => :type_var}],
                           :kind       => :generic_type},
                          {:type       => "Hash",
                           :parameters =>  [{:type => "T", :bound => "String", :kind => :type_var},
                                            {:type => "U", :bound => "Object", :kind => :type_var}],
                           :kind       => :generic_type}])
  end
end
