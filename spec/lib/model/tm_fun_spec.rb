require_relative '../../spec_helper'

describe TypedRb::Model::TmFun do
  it 'parses a function with rest args' do
    parsed = parse('def f(a,*rest); end')
    expect(parsed).to be_instance_of(described_class)
    expect(parsed.args.size).to eq(2)
    expect(parsed.args.last.first).to eq(:restarg)
    parsed.check_type(TypedRb::Types::TypingContext.top_level)
  end
end
