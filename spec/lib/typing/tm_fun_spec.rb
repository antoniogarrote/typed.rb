require_relative '../../spec_helper'

describe TypedRb::Model::TmFun do
  before :each do
    ::BasicObject::TypeRegistry.clear
  end

  let(:code) do
    text = <<__CODE
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
    TypedRb::Model::GenSym.reset
    parser = TypedRb::AstParser.new
    parser.parse(typed_code)
  end

  context 'with validly typed code' do
    it 'should be possible to type check a method and method application' do
      expect do
        ast.check_type(TypedRb::Types::TypingContext.new)
      end.to_not raise_error
    end
  end

  context 'with not matching arg type in function definition' do
    let(:code) do
      text = <<__CODE
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
      expect do
        ast.check_type(TypedRb::Types::TypingContext.new)
      end.to raise_error(TypedRb::Types::UncomparableTypes)
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
      expect do
        ast.check_type(TypedRb::Types::TypingContext.new)
      end.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context 'with application without optional arguments' do
    let(:code) do
      text = <<__CODE
       ts '#f / Integer -> Integer -> String'
       def f(a,b=1)
         'string'
       end

       f(2)

       f(2,3)
__CODE
      text
    end

    it 'should not raise a type error' do
      expect do
        ast.check_type(TypedRb::Types::TypingContext.top_level)
      end.not_to raise_error
    end
  end

  context 'with application with rest args' do

    context 'with correct types' do
      let(:code) do
        text = <<__CODE
       ts 'type Array[T]'

       ts '#f / Integer -> Integer... -> String'
       def f(a, *b)
         'string'
       end

       f(2, 3, 4, 5)
__CODE
        text
      end

      it 'should not raise a type error' do

        expect do
          res = ast.check_type(TypedRb::Types::TypingContext.top_level)
          expect(res.ruby_type).to eq(String)
        end.not_to raise_error
      end
    end

    context 'with erroneous types' do
      let(:code) do
        text = <<__CODE
       ts 'type Array[T]'

       ts '#f / Integer -> Integer... -> String'
       def f(a, *b)
         'string'
       end

       f(2, 'a', 'b')
__CODE
        text
      end

      it 'should raise a type error' do

        expect do
          ast.check_type(TypedRb::Types::TypingContext.top_level)
        end.to raise_error(TypedRb::TypeCheckError)
      end
    end

    context 'with missing rest args' do
      let(:code) do
        text = <<__CODE
       ts 'type Array[T]'

       ts '#f / Integer -> Integer... -> String'
       def f(a, *b)
         'string'
       end

       f(2)
__CODE
        text
      end

      it 'should not raise a type error' do

        expect do
          res = ast.check_type(TypedRb::Types::TypingContext.top_level)
          expect(res.ruby_type).to eq(String)
        end.not_to raise_error
      end
    end
  end
end
