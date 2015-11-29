require_relative '../../spec_helper'

describe String do
  let(:language) { TypedRb::Language.new }

  describe '#each_line' do
    describe '/ &(String -> unit) -> String' do
      it 'type checks , positive case' do
        code = <<__CODE
        ts '#str_fn / String -> unit'
        def str_fn(s); end

        "".each_line{ |s| str_fn(s) }
__CODE
        result = language.check(code)
        expect(result.to_s).to eq('String')
      end

      it 'type checks / &(String -> unit) -> String, negative case' do
        code = <<__CODE
        ts '#int_fn / Integer -> unit'
        def int_fn(i); end

        "".each_line{ |s| int_fn(s) }
__CODE
        expect {
          language.check(code)
        }.to raise_error(TypedRb::Types::UncomparableTypes)
      end
    end

    describe '-> Enumerator[String]' do
      it 'type checks' do
        result = language.check('"".each_line')
        expect(result.to_s).to eq('Enumerator[String]')
      end
    end

    describe '/ String -> &(String -> unit) -> String' do
      it 'type checks , positive case' do
        code = <<__CODE
        ts '#str_fn / String -> unit'
        def str_fn(s); end

        "".each_line(''){ |s| str_fn(s) }
__CODE
        result = language.check(code)
        expect(result.to_s).to eq('String')
      end

      it 'type checks / &(String -> unit) -> String, negative case' do
        code = <<__CODE
        ts '#int_fn / Integer -> unit'
        def int_fn(i); end

        "".each_line(''){ |s| int_fn(s) }
__CODE
        expect {
          language.check(code)
        }.to raise_error(TypedRb::Types::UncomparableTypes)
      end
    end

    describe 'String -> Enumerator[String]' do
      it 'type checks' do
        result = language.check('"".each_line("")')
        expect(result.to_s).to eq('Enumerator[String]')
      end
    end
  end

  describe '#scan' do
    describe 'Regexp -> &(String... -> unit) -> String' do
      it 'type checks, positive case' do
        code = <<__CODE
         ts '#str_array_fn / Array[String] -> unit'
         def str_array_fn(ss); end

         "".scan(/\n/) { |ss| str_array_fn(ss) }
__CODE
        result = language.check(code)
        expect(result.to_s).to eq('String')
      end

      it 'type checks, negative case' do
        code = <<__CODE
         ts '#int_array_fn / Array[Integer] -> unit'
         def int_array_fn(is); end

         "".scan(/\n/) { |ss| int_array_fn(ss) }
__CODE
        expect {
          language.check(code)
        }.to raise_error(TypedRb::Types::UncomparableTypes)
      end
    end
  end
end
