require_relative '../../spec_helper'

describe TypedRb::Model::TmSend do
  let(:language) { TypedRb::Language.new }

  context 'with class methods' do
    it 'is possible to send messages to the class objects' do
      expr = <<__END
       class Integer
         ts '#+ / Integer -> Integer'
       end

       class TypeCM1

         ts '.a / -> Integer'
         def self.a
           1
         end

         class << self
           ts '.b / -> Integer'
           def b
             2
           end
         end

         class << TypeCM1
           ts '.c / -> Integer'
           def c
             3
           end
         end
       end

       TypeCM1.a + TypeCM1.c  + TypeCM1.c
__END

      result = language.check(expr)
      expect(result.ruby_type).to eq(Integer)
    end
  end
end
