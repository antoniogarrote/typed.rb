require_relative '../../spec_helper'

describe TypedRb::Model::TmSymbolInterpolation do

  it 'parses interpolation of strings' do
    parsed = parse(':"this #{is} an #{interpolation}"')
    expect(parsed).to be_instance_of(described_class)
    expect(parsed.units.size).to eq(4)
  end
end
