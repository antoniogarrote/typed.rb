require_relative '../../spec_helper'

describe TypedRb::Model::TmSymbol do

  it 'parses a symbol' do
    parsed = parse(':test')
    expect(parsed).to be_instance_of(described_class)
  end
end
