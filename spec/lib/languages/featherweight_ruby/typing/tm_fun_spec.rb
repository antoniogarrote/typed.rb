require_relative '../spec_helper'

describe TypedRb::Languages::FeatherweightRuby::Model::TmFun do

  before :each do
    ::BasicObject::TypeRegistry.registry.clear
  end

  let(:code) do
    text =<<__CODE
      class A
        ts '#f1 / Integer -> String'
        def f1(num)
          'String'
        end

        ts '#f2 / Integer -> String'
        def f2(num=2)
          f1(num)
        end
      end
__CODE
    text
  end

  let(:typed_code) do
    $TYPECHECK = true
    eval(code, TOPLEVEL_BINDING)
    ::BasicObject::TypeRegistry.normalize_types!
    code
  end

  let(:ast) do
    TypedRb::Languages::FeatherweightRuby::Model::GenSym.reset
    parser = TypedRb::Languages::FeatherweightRuby::Parser.new
    parser.parse(typed_code)
  end

  context 'with validly typed code' do
    it 'should be possible to type check a method and method application' do
      expect {
        ast.check_type(TypedRb::Languages::FeatherweightRuby::Types::TypingContext.new)
      }.to_not raise_error
    end
  end

  context 'with not matching arg type in function definition' do

    let(:code) do
      text =<<__CODE
      class A
        ts '#f1 / Integer -> String'
        def f1(num='text')
          'String'
        end

        ts '#f2 / Integer -> String'
        def f2(num)
          f1(num)
        end
      end
__CODE
      text
    end

    it 'should raise a type error' do
      expect {
        ast.check_type(TypedRb::Languages::FeatherweightRuby::Types::TypingContext.new)
      }.to raise_error(TypedRb::Languages::FeatherweightRuby::Model::TypeError)
    end
  end

  context 'with not matching return type in function definition' do

    let(:code) do
      text =<<__CODE
      class A
        ts '#f1 / Integer -> String'
        def f1(num)
          2
        end

        ts '#f2 / Integer -> String'
        def f2(num)
          f1(num)
        end
      end
__CODE
      text
    end

    it 'should raise a type error' do
      expect {
        ast.check_type(TypedRb::Languages::FeatherweightRuby::Types::TypingContext.new)
      }.to raise_error(TypedRb::Languages::FeatherweightRuby::Model::TypeError)
    end
  end
end
