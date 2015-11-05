require_relative '../../spec_helper'

describe Enumerator do
  let(:language) { TypedRb::Language.new }

  describe '#initialize' do
    it 'type checks / Integer -> Enumerator[T]' do
      result = language.check('Enumerator.(Integer).new(10)')
      expect(result.to_s).to eq('Enumerator[Integer]')
    end

    it 'type checks / &(Enumerator::Yielder[T] -> unit) -> Enumerator[T]' do
      result = language.check('Enumerator.(Integer).new { |y| y.yield(10) }')
      expect(result.to_s).to eq('Enumerator[Integer]')

      expect {
        language.check('Enumerator.(Integer).new { |y| y.yield("string") }')
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end

    it 'type checks / Object -> Symbol -> Enumerator[T]' do
      result = language.check('Enumerator.(String).new Object.new')
      expect(result.to_s).to eq('Enumerator[String]')
    end
  end

  describe '#each' do
    it 'type checks / -> Enumerator[T]' do
      result = language.check('Enumerator.(Integer).new { |y| y.yield(10) }.each')
      expect(result.to_s).to eq('Enumerator[Integer]')
    end

    it 'type checks / &([T] -> unit) -> Object' do
      code = <<__CODE
       Enumerator.(Integer).new { |y| y.yield(10) }.each do |i|
         i + 1
       end
__CODE
      result = language.check(code)
      expect(result.to_s).to eq('Object')

      code = <<__CODE
       ts '#str_fn / String -> unit'
       def str_fn(s); end

       Enumerator.(Integer).new { |y| y.yield(10) }.each do |i|
         str_fn(i)
       end
__CODE
      expect {
        language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  describe '#each_with_index' do
    it 'type checks / -> Enumerator[Pair[T][Integer]]' do
      result = language.check('Enumerator.(Integer).new { |y| y.yield(10) }.each_with_index')

      expect(result.to_s).to eq('Enumerator[Pair[Integer][Integer]]')
    end

    xit 'type checks / -> Enumerator[Pair[T][Integer]] multiple invocations' do
      result = language.check('Enumerator.(Integer).new { |y| y.yield(10) }.each_with_index.each_with_index')
      expect(result.to_s).to eq('Enumerator[Pair[Pair[Integer][Integer]][Integer]]')
    end

    it 'type checks / &([T] -> Integer -> unit) -> Object' do
      code = <<__CODE
       ts '#int_int_fn / Integer -> Integer -> Integer'
       def int_int_fn(x,y); x + y; end
       Enumerator.(Integer).new { |y| y.yield(10) }.each_with_index do |e, i|
          int_int_fn(e,i)
       end
__CODE

      result = language.check(code)
      expect(result.to_s).to eq('Object')

      expect {
        code = <<__CODE
       ts '#int_int_fn / Integer -> Integer -> Integer'
       def int_int_fn(x,y); y; end
       Enumerator.(String).new { |y| y.yield("str") }.each_with_index do |e, i|
          int_int_fn(e,i)
       end
__CODE

        result = language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  describe '#each_with_object' do
    xit 'type checks[E] / -> Enumerator[Pair[T][E]]' do
      result = language.check('Enumerator.(Integer).new { |y| y.yield(10) }.each_with_object("String")')

      expect(result.to_s).to eq('Enumerator[Pair[Integer][String]]')
    end
  end
end
