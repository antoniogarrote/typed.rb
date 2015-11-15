require_relative '../../spec_helper'

describe Enumerable do
  let(:language) { TypedRb::Language.new }

  describe '#all?' do
    context 'for Array' do
      it 'type checks / &([T] -> Boolean) -> Boolean' do
        code = <<__CODE
       ts '#int_fn / Integer -> Boolean'
       def int_fn(e); true; end
       Array.(Integer).new.all? { |e| int_fn(e) }
__CODE
        result = language.check(code)

        expect(result.to_s).to eq('Boolean')

        expect {
          code = <<__CODE
       ts '#str_fn / String -> Boolean'
       def str_fn(e); true; end
       Array.(Integer).new.all? { |e| str_fn(e) }
__CODE
          language.check(code)
        }.to raise_error(TypedRb::Types::UncomparableTypes)
      end
    end

    context 'for Hash' do
      it 'type checks / &([T] -> Boolean) -> Boolean' do
        code = <<__CODE
       ts '#str_int_fn / String -> Integer -> Boolean'
       def str_int_fn(s,i); true; end
       Hash.(String,Integer).new.all? { |k,v| str_int_fn(k,v) }
__CODE
        result = language.check(code)

        expect(result.to_s).to eq('Boolean')

        code = <<__CODE
       ts '#str_int_fn / String -> Integer -> Boolean'
       def str_int_fn(s,i); true; end
       Hash.(String,Integer).new.all? { |p| str_int_fn(p.first,p.second) }
__CODE
        result = language.check(code)

        expect(result.to_s).to eq('Boolean')

        expect {
          code = <<__CODE
       ts '#str_str_fn / String -> String -> Boolean'
       def str_str_fn(s,i); true; end
       Hash.(String,Integer).new.all? { |k,v| str_str_fn(k,v) }
__CODE
          language.check(code)
        }.to raise_error(TypedRb::Types::UncomparableTypes)

        expect {
          code = <<__CODE
       ts '#str_str_fn / String -> String -> Boolean'
       def str_str_fn(s,i); true; end
       Hash.(String,Integer).new.all? { |p| str_str_fn(p.first,p.second) }
__CODE
          language.check(code)
        }.to raise_error(TypedRb::Types::UncomparableTypes)
      end
    end
  end

  describe '#chunk' do
    describe '&([T] -> Boolean) -> Enumerator[Pair[Boolean][Array[T]]]' do
      it 'type checks it correctly, positive case' do
        code = <<__CODE
           ts "#int_bool_fn / Integer -> Boolean"
           def int_bool_fn(i); true; end

           ts '#bool_int_ary_fn / Boolean -> Array[Int] -> unit'
           def bool_int_ary_fn(b,a); nil; end

           [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5].chunk { |n|
              int_bool_fn(n)
           }.each { |even, ary|
              bool_int_ary_fn(even, ary)
           }
__CODE
        result = language.check(code)

        expect(result.to_s).to eq('Object')
      end

      it 'type checks it correctly, negative case 1' do
        code = <<__CODE
           ts "#float_bool_fn / Float -> Boolean"
           def float_bool_fn(f); true; end

           [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5].chunk { |n|
              float_bool_fn(n)
           }
__CODE

        expect {
          language.check(code)
        }.to raise_error(TypedRb::Types::UncomparableTypes)
      end

      it 'type checks it correctly, negative case 2' do
        code = <<__CODE
           ts "#int_bool_fn / Integer -> Boolean"
           def int_bool_fn(i); true; end

           ts "#int_fn / Integer -> unit"
           def int_fn(i); nil; end

           [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5].chunk { |n|
              int_bool_fn(n)
           }.each { |b,i|
              int_fn(i)
           }
__CODE

        expect {
          language.check(code)
        }.to raise_error(TypedRb::Types::UncomparableTypes)
      end
    end
  end

  describe '#detect' do
    describe '&([T] -> Boolean) -> [T]' do
      it 'type checks it correctly, positive case' do
        code = <<__CODE
           ts "#int_bool_fn / Integer -> Boolean"
           def int_bool_fn(i); true; end

           [1, 2, 3, 4].detect{ |i| int_bool_fn(i) }
__CODE
        result = language.check(code)

        expect(result.to_s).to eq('Integer')
      end

      it 'type checks it correctly, negative case' do
        code = <<__CODE
           ts "#float_bool_fn / Float -> Boolean"
           def float_bool_fn(f); true; end

           [1, 2, 3, 4].detect { |i| float_bool_fn(i) }
__CODE
        expect {
          language.check(code)
        }.to raise_error(TypedRb::Types::UncomparableTypes)
      end
    end

    describe '[T] -> Enumerator[T]' do
      it 'type checks it correctly, positive case' do
        code = <<__CODE
           [1, 2, 3, 4].detect
__CODE
        result = language.check(code)

        expect(result.to_s).to eq('Enumerator[Integer]')
      end
    end
  end

  describe '#each_cons' do
    describe 'Integer -> Enumerator[Array[T]]' do
      it 'type checks it correctly, positive case' do
        code = <<__CODE
       [1,2,3].each_cons(2)
__CODE
        result = language.check(code)

        expect(result.to_s).to eq('Enumerator[Array[Integer]]')
      end

      it 'type checks it correctly, positive case' do
        code = <<__CODE
       [1,2,3].each_cons(2).first
__CODE
        result = language.check(code)

        expect(result.to_s).to eq('Array[Integer]')
      end
    end
  end
end
