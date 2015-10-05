require_relative '../../spec_helper'

describe TypedRb::Model::TmDefined do

  it 'parses a defined invocation' do
    parsed = parse('defined? 2')
    expect(parsed).to be_instance_of(described_class)
    expect(parsed.expression).to be_instance_of(TypedRb::Model::TmInt)
  end
end
