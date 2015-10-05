require_relative '../../spec_helper'

describe TypedRb::Model::TmDefined do
  let(:language) { TypedRb::Language.new }

  it 'defined invocations' do
      expr = 'defined? 2'

      result = language.check(expr)
      expect(result.ruby_type).to eq(String)
  end
end
