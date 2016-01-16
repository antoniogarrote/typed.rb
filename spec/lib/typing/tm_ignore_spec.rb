require_relative '../../spec_helper'

describe BasicObject do
  let(:language) { TypedRb::Language.new }

  it 'Ignores functions marked with #ts_ignore' do
    expr = <<__CODE
      class TypeA

        ts '#fa / -> String'
        ts_ignore
        def fa
          2.0
        end

      end

      TypeA.new.fa
__CODE

    result = language.check(expr)
    expect(result.to_s).to eq('String')
  end
end