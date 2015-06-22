require_relative '../spec_helper'

describe TypedRb::Languages::PolyFeatherweightRuby::Model::TmAbs do

  it 'parses a lambda function with multiple args' do
    parsed = parse('->(x,y) { x + y }')

    expect(parsed).to be_instance_of(described_class)
    expect(parsed.args[0][1]).to be_instance_of(TypedRb::Languages::PolyFeatherweightRuby::Types::Polymorphism::TypeVariable)
    expect(parsed.args[1][1]).to be_instance_of(TypedRb::Languages::PolyFeatherweightRuby::Types::Polymorphism::TypeVariable)
    expect(parsed.args.size).to eq(2)
    expect(parsed.term.receiver.val).to eq(parsed.args[0][1].variable)
    expect(parsed.term.args[0].val).to eq(parsed.args[1][1].variable)
  end

  it 'renames free variables in the term' do
    parsed = parse('->(bound) { bound + free }')

    expect(parsed.term.args[0].message).to eq(:free)
    parsed.rename('free','x').rename('bound','y')
    # bound -/-> y, it's bound
    expect(parsed.term.receiver.val).to eq(parsed.args[0][1].variable)
    # free --> x, it's free
    expect(parsed.term.args[0].message).to eq(:x)
  end

  it 'check types creating the right constraints for the type variables' do
    parsed = parse('->(x,y) { x + y }')

    result = parsed.check_type(top_level_typing_context)
    expect(result.from.size).to eq(2)
    expect(result.from[0]).to is_a(TypedRb::Languages::PolyFeatherweightRuby::Types::Polymorphism::TypeVariable)
    expect(result.from[0].constraints[0][1]).to eq(:send)
    expect(result.from[1]).to is_a(TypedRb::Languages::PolyFeatherweightRuby::Types::Polymorphism::TypeVariable)
    expect(result.to).to is_a(TypedRb::Languages::PolyFeatherweightRuby::Types::Polymorphism::TypeVariable)
    binding.pry
  end
end
