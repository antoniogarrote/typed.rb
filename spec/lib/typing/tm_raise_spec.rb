require_relative '../../spec_helper'

describe TypedRb::Model::TmError do

  let(:language) { TypedRb::Language.new }

  context 'with raise, one error' do
    it 'type-checks it correctly' do
      code = <<__END
      1 || raise(StandardError)
__END
      result = language.check(code)
      expect(result.to_s).to eq('Integer')
    end
  end

  context 'with raise, only errors' do
    it 'type-checks it correctly' do
      code = <<__END
      ts '#x / -> Integer'
      def x
        raise(StandardError) || raise(StandardError)
      end
__END
      expect {
        language.check(code)
      }.not_to raise_error
    end
  end

end
