require_relative '../../spec_helper'

describe Array do
  let(:language) { TypedRb::Language.new }

  context '#initialize' do
    it 'type checks / -> Array[T]' do
      result = language.check('Array.(Integer).new')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Integer)
    end

    it 'type checks / Integer -> Array[T]' do
      result = language.check('Array.(Integer).new(3)')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Integer)
    end

    it 'type checks / Integer -> [T] -> Array[T]' do
      result = language.check('Array.(String).new(3, "start")')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(String)

      expect {
        result = language.check('Array.(String).new(3, 0)')
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context '#[]' do
    it 'type checks / Object -> Object' do
      result = language.check('Array.(Integer).new(10,0)[0]')
      expect(result.ruby_type).to eq(Object)
    end

    it 'type checks / Integer -> Integer - Array[T]' do
      result = language.check('Array.(Integer).new(10,0)[0, 3]')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Integer)
    end
  end

  context '#collect[E]' do
    it 'type checks / &([T] -> [E]) -> Array[E]' do
      result = language.check('Array.(Integer).new(10,0).collect{ |e| e.to_s }')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(String)
    end
  end

  context '#concat' do
    it 'type checks / Array[T] -> Array[T]' do
      result = language.check('Array.(Integer).new(10,0).concat(Array.(Integer).new(10,0))')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Integer)

      expect {
        language.check('Array.(Integer).new(10,0).concat(Array.(String).new(10,"blah"))')
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context '#count' do
    it 'type checks / &([T] -> Boolean) -> Integer' do
      result = language.check('Array.(Integer).new(10,0).count(0)')
      expect(result.ruby_type).to eq(Integer)

      result = language.check('Array.(Integer).new(10,0).count{ |x| x == 0 }')
      expect(result.ruby_type).to eq(Integer)

      expect {
        code = <<__CODE
          ts '#testarrs / String -> Boolean'
          def testarrs(s); true; end

          Array.(Integer).new(10,0).count{ |x| testarrs(x) }
__CODE
        language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context '#eql?' do
    it 'type checks / Array[?] -> Boolean' do
      code = <<__CODE
        as = Array.(Integer).new(10,0)
        bs = Array.(String).new(10,'')

        as.eql?(bs)
__CODE
      result = language.check(code)
      expect(result.ruby_type).to eq(TrueClass)
    end
  end
end
