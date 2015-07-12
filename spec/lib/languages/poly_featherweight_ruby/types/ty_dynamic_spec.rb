require_relative '../spec_helper'

describe TypedRb::Languages::PolyFeatherweightRuby::Types::TyDynamic do

  context 'with not typed code' do

    it 'supports untyped constructors' do
      code = <<__CODE
       class Dyn1

         ts '#put / Integer -> unit'
         def put(n)
           @value = n
         end

         def take
           @value
         end

       end

       Dyn1.new
__CODE

      parsed = TypedRb::Languages::PolyFeatherweightRuby::Language.new.check(code)

      expect(parsed.ruby_type).to eq(Dyn1)
    end

    it 'uses type Dynamic for the untyped code' do
      code = <<__CODE
       class Dyn1

         ts '#put / Integer -> unit'
         def put(n)
           @value = n
         end

         def take
           @value
         end

       end

       Dyn1.new.take
__CODE

      parsed = TypedRb::Languages::PolyFeatherweightRuby::Language.new.check(code)

      expect(parsed).to be_instance_of(described_class)
    end

    it 'can check mixed typed/untyped class definitions' do
      code = <<__CODE
       class Dyn1

         def initialize(x); end

         ts '#put / Integer -> Integer'
         def put(n)
           @value = n
         end

         def take
           @value
         end

       end

       Dyn1.new('test').put(3)
__CODE

      parsed = TypedRb::Languages::PolyFeatherweightRuby::Language.new.check(code)

      expect(parsed.ruby_type).to eq(Integer)
    end

    it 'can check typed code invoking untyped code in the definition' do
      code = <<__CODE
       class Dyn1

         def initialize(x); end

         ts '#put / Integer -> Integer'
         def put(n)
            take + n
         end

         def take
           0
         end

       end

       Dyn1.new('test').put(3)
__CODE

      parsed = TypedRb::Languages::PolyFeatherweightRuby::Language.new.check(code)

      expect(parsed.ruby_type).to eq(Integer)
    end
  end
end
