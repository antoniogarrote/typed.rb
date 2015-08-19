require_relative '../../spec_helper'

describe TypedRb::Model::TmSend do
  let(:language) { TypedRb::Language.new }

  it 'applies arguments to generic methods' do
    code = <<__END
      class TestGM1
        ts '#gm[T][E] / [T] -> &([T] -> [E]) -> [E]'
        def gm(t)
          yield t
        end
      end

      TestGM1.new.gm(true) { |t| false }
      TestGM1.new.gm(1) { |t| 'string' }
__END
    result = language.check(code)
    expect(result.ruby_type).to eq(String)
  end

  it 'applies arguments to generic methods mixing class and method type variables' do
    code = <<__END
      ts 'type TestGM2Array[T]'
      class TestGM2Array

        ts '#initialize / [T] -> unit'
        def initialize(t)
         @t = t
        end

        ts '#map[E] / [T] -> Array[T] -> &([T] -> [E]) -> Array[E]'
        def map(x, xs)
          c = Array.('[E]').new
          c << yield(@t)
          c
        end
      end

      ts '#c / String -> Integer'
      def c(x)
        0
      end

      TestGM2Array.(String).new('value').map('other', nil) { |v| c(v) }
__END
    result = language.check(code)
    expect(result.ruby_type).to eq(Array)
    expect(result.type_vars[0].bound.ruby_type).to eq(Integer)
  end

  it 'type checks the body of generic methods' do
    code = <<__END
      class TestGM3

        ts '#test[E] / [E] -> Array[E]'
        def test(e)
          es = Array.('[E]').new
          es << e
          es
        end
      end

      TestGM3.new.test('value')
__END
    result = language.check(code)
    puts result.to_s
    expect(result.ruby_type).to eq(Array)
    expect(result.type_vars[0].bound.ruby_type).to eq(String)
  end
end
