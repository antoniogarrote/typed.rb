require_relative '../../spec_helper'

describe TypedRb::Model::TmRegexp do

  let(:language) { TypedRb::Language.new }

  context 'with a regular expression' do

    it 'parsed the Regexp type correctly' do
      result = language.check('/test/')
      expect(result).to eq(tyregexp)
    end
  end
end
