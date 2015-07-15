require_relative '../../spec_helper'

describe TypedRb::Model::TmGlobalVar do
  let(:language) { TypedRb::Language.new }

  context 'with a valid global var' do
    it 'is possible to type-check the global var' do
      expr = <<__END
        $test = 1
        $test
__END

      result = language.check(expr)
      expect(result.bound.ruby_type).to eq(Integer)
    end

    it 'is possible to type-check errors in global var typing' do
      expr = <<__END
        $test = 1
        $test = 'test'

        ts '#x / Integer -> unit'
        def x(n); end

        x($test)
__END

      expect {
        language.check(expr)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end
end
