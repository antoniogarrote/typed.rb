require_relative '../../spec_helper'

describe Object do
  let(:language) { TypedRb::Language.new }

  describe 'Strings' do
    it 'is a Showable' do
      code = <<__CODE
        ts '#st1 / Showable -> Showable'
        def st1(s); s; end

        st1('hey')
__CODE
      result = language.check(code)
      expect(result.ruby_type).to eq(Showable)
    end
  end

  describe 'Symbols' do
    it 'is a Showable' do
      code = <<__CODE
        ts '#st1 / Showable -> Showable'
        def st1(s); s; end

        st1(:hey)
__CODE
      result = language.check(code)
      expect(result.ruby_type).to eq(Showable)
    end
  end
end
