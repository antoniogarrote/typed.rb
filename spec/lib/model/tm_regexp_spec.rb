require_relative '../../spec_helper'

describe TypedRb::Model::TmRegexp do

  it 'parses a regular expression' do
    parsed = parse('/[Rr]eg[Ee]xp/')
    expect(parsed).to be_instance_of(described_class)
  end
end
