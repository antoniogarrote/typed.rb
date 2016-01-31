require_relative '../../spec_helper'

describe TypedRb::Model::TmModule do
  let(:language) { TypedRb::Language.new }

  it 'includes a module in a class' do
    code = <<__CODE
       module TMod2
        ts '#x / -> String'
        def x; 'test'; end
       end

       include TMod2
__CODE

    expect do
      language.check(code)
    end.to_not raise_error
  end

  it 'detects errors in the mixed in type' do
    code = <<__CODE
      module TMod3
        ts '#x / -> String'
        def x
          return_string
        end
      end

      class TMod3C1
        include TMod3
        ts '#return_string / -> Integer'
        def return_string; 2; end
      end
__CODE

    expect {
      language.check(code)
    }.to raise_error(TypedRb::Types::UncomparableTypes,
                     /Cannot compare types Integer <=> String/)
  end

  it 'includes a module referencing instance variables in a class' do
    code = <<__CODE
       module TMod4
        ts '#x / Integer -> unit'
        def x(i); @a = i; end
       end

       class TMod4C1
         include TMod4

         ts '#a / -> Integer'
         def a; @a; end
       end

       TMod4C1.new.a
__CODE

    result = language.check(code)
    expect(result.ruby_type).to eq(Integer)
  end

  it 'typechecks the inclusion of a module in multiple classes' do
    code = <<__CODE
       module TMod4
        ts '#x / Integer -> unit'
        def x(i); @a = i; end
       end

       class TMod4C1
         include TMod4

         ts '#a / -> Integer'
         def a; @a; end
       end

       class TMod4C2
         include TMod4
       end

       TMod4C2.new.x(3)
       TMod4C1.new.a
__CODE

    result = language.check(code)
    expect(result.ruby_type).to eq(Integer)
  end

  it 'typechecks the inclusion of a polymorphic module into a class' do
    code = <<__CODE
     module TMod5
       ts '#head[T] / Array[T] -> [T]'
       def head(xs); xs.first; end
     end

     class TMod5C
        include TMod5
     end

     TMod5C.new.head([1,2,3])
__CODE

    result = language.check(code)
    expect(result.ruby_type).to eq(Integer)
  end

  it 'typechecks the inclusion of a polymorphic nested module into a class' do
    code = <<__CODE
    module Categories
      module Polymorphism

        ts '#head[A] / Array[A] -> [A]'
        def head(xs)
          xs.first
        end

      end
    end

    include Categories::Polymorphism

    head([1,2,3])
__CODE

    result = language.check(code)
    expect(result.ruby_type).to eq(Integer)
  end

  it 'typechecks the inclusion of a polymorphic module into the top level object' do
    code = <<__CODE
     module TMod5
       ts '#head[T] / Array[T] -> [T]'
       def head(xs); xs.first; end
     end

     include TMod5

     head([1,2,3])
__CODE

    result = language.check(code)
    expect(result.ruby_type).to eq(Integer)
  end

  it 'typechecks modules with generic parameters' do
    code = <<__CODE
    ts 'type TMod6[T]'
    module TMod6
       ts '#test1 / Array[T] -> [T]'
       def test1(x); x.first; end
    end

    ts 'type TestTMod6 super TMod6[String]'
    class TestTMod6
      include TMod6
    end

    TestTMod6.new.test1(['a','b','c'])
__CODE

    result = language.check(code)
    expect(result.ruby_type).to eq(String)
  end

   it 'typechecks modules with generic parameters 2' do
    code = <<__CODE
  module Categories
    ts 'type Categories::Equal[T]'
    module Equal

      ts '#eq? / [T] -> Boolean'
      def eq?(o); self.eql?(o); end

      ts '#not_eq? / [T] -> Boolean'
      def not_eq?(o); ! self.eq?(o); end

    end
  end

  ts 'type String super Categories::Equal[String]'
  class String
    include Categories::Equal
  end

  "test".eq? "other"
__CODE

    result = language.check(code)
    expect(result.to_s).to eq('Boolean')
  end
end
