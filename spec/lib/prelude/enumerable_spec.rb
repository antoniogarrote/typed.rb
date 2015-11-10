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
end
