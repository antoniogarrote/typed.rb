require_relative '../../spec_helper'

describe TypedRb::Model::TmTry do

  let(:language) { TypedRb::Language.new }

  context 'with no rescue term' do
    it 'type-checks it correctly' do
      code = <<__END
        begin
           2 + 2
        end
__END
      result = language.check(code)
      expect(result.to_s).to eq('Integer')
    end
  end
  context 'with rescue term' do
    it 'type-checks it correctly, positive case' do
      code = <<__END
        begin
           2 + 2
        rescue StandardError => e
           0
        end
__END
      result = language.check(code)
      expect(result.to_s).to eq('Integer')
    end

    it 'type-checks it correctly, negative case' do
      code = <<__END
        begin
           2 + 2
        rescue
           'string'
        end
__END
      expect {
        language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context 'with multiple rescue clauses' do
    it 'type-checks it correctly' do
      code = <<__END
        begin
           2 + 2
        rescue StandardError => e
        rescue
           0
        end
__END
      result = language.check(code)
      expect(result.to_s).to eq('Integer')
    end
  end

  context 'with a error return type' do
    it 'type-checks it correctly' do
      code = <<__END
        begin
           Object.new
        rescue StandardError, Object => e
           e
        end
__END
      result = language.check(code)
      expect(result.to_s).to eq('Object')
    end
  end
end
