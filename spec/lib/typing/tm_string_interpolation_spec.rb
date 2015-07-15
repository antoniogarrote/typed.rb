require_relative '../../spec_helper'

describe TypedRb::Model::TmStringInterpolation do

  let(:language) { TypedRb::Language.new }

  context 'with a interpolated string' do

    it 'type-checks it correctly' do
      code = <<__END
        a = 1
        b = 'interpolated'
        "This is \#{a} string \#{b}"
__END
      result = language.check(code)
      expect(result).to eq(tystring)
    end
  end
end
