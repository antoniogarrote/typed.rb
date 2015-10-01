require_relative '../../spec_helper'

describe Hash do
  let(:language) { TypedRb::Language.new }

  context '#initialize' do
    it 'type checks / -> Hash[S][T]' do
      result = language.check('Hash.(String,Integer).new')
      expect(result.to_s).to eq('Hash[String][Integer]')
    end

    xit 'type checks / -> Hash[S][T] with a literal type annotation' do
      result = language.check("Hash.('[String][Integer]').new")
      expect(result.to_s).to eq('Hash[String][Integer]')
    end

    it 'type checks / -> [T] -> Hash[S][T]' do
      result = language.check("Hash.(String,Integer).new(1)")
      expect(result.to_s).to eq('Hash[String][Integer]')

      expect {
        language.check("Hash.(String,Integer).new('string')")
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end

    xit 'type checks / &(Hash[S][T] -> unit) -> Hash[S][T]' do
      result = language.check("Hash.(String,Integer).new { |acc,k| acc[k] = 0}")
      expect(result.to_s).to eq('Hash[String][Integer]')

      expect {
        language.check("Hash.(String,Integer).new { |acc,k| acc[k] = 'string'}")
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end
end
