require_relative '../../spec_helper'

describe TypedRb::Model::TmSend do
  let(:language) { TypedRb::Language.new }

  it 'applies arguments to generic methods' do
    code = <<__END
      class TestGM1
        ts '#gm / [T] -> &([T] -> [E]) -> [E]'
        def gm(t)
          yield t
        end
      end

      TestGM1.new.gm(1) { |t| 'string' }
__END
    result = language.check(code)
    #binding.pry
    expect(result.ruby_type).to eq(String)
  end
end
