require_relative '../../spec_helper'

describe TypedRb::Model::TmLet do
  before :each do
    ::BasicObject::TypeRegistry.clear
  end

  let(:code) do
    text =<<__CODE
     a = 3
     a
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

  context 'with simple assignment' do
    it 'should be possible to get the right type' do
      type = ast.check_type(TypedRb::Types::TypingContext.top_level)
      expect(type.to_s).to eq('Integer')
    end
  end


  context 'with variable assignment' do
    let(:code) do
      text =<<__CODE
     a = 3
     b = a
     b
__CODE
      text
    end

    it 'should be possible to get the right type' do
      type = ast.check_type(TypedRb::Types::TypingContext.top_level)
      expect(type.to_s).to eq('Integer')
    end
  end


  context 'with multiple variable assignment' do
    let(:code) do
      text =<<__CODE
     a = 3
     b = "blah"
     a = b
     a
__CODE
      text
    end

    it 'should be possible to get the right type' do
      type = ast.check_type(TypedRb::Types::TypingContext.top_level)
      expect(type.to_s).to eq('String')
    end
  end

  context 'in function application' do
    context 'with correctly typed code' do
      let(:code) do
        <<__CODE
        ts '#f / Integer -> String'
        def f(x)
          a = 'hola'
          a
        end

        ts '#g / Integer -> String'
        def g(y)
          a = y
          f(a)
        end
__CODE
      end

      it 'should be possible to be passed as an argument to a function' do
        expect {
          ast.check_type(TypedRb::Types::TypingContext.top_level)
        }.to_not raise_error
      end
    end

    context 'with incorrectly typed code' do
      let(:code) do
        <<__CODE
        ts '#f / String -> String'
        def f(x)
          x
        end

        ts '#g / Integer -> String'
        def g(y)
          a = y
          f(a)
        end
__CODE
      end

      it 'should be possible to be passed as an argument to a function' do
        expect {
          ast.check_type(TypedRb::Types::TypingContext.top_level)
        }.to raise_error(TypedRb::Types::UncomparableTypes)
      end
    end
  end

end
