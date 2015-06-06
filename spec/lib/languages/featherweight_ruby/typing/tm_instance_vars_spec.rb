require_relative '../../../../spec_helper'

describe TypedRb::Languages::FeatherweightRuby::Model::TmInstanceVar do

  before :each do
    ::BasicObject::TypeRegistry.registry.clear
  end

  let(:code) do
    text =<<__CODE
      class A
        ts '\#@a / Integer'

        ts '#initialize / -> unit'
        def initialize
          @a = 'error'
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

  context 'with invalid type assignment' do
    it 'should raise a type error' do
      expect {
        ast.check_type(TypedRb::Languages::FeatherweightRuby::Types::TypingContext.new)
      }.to raise_error(TypedRb::Languages::FeatherweightRuby::Model::TypeError)
    end
  end

  context 'with valid type assignment' do
    let(:code) do
      text =<<__CODE
      class A
        ts '\#@a / Integer'

        ts '#initialize / -> unit'
        def initialize
          @a = 10
          a(@a)
        end

        ts '#a / Integer -> Integer'
        def a(x)
          x
        end
      end
__CODE
      text
    end

    it 'should not raise a type error' do
      expect {
        ast.check_type(TypedRb::Languages::FeatherweightRuby::Types::TypingContext.new)
      }.to_not raise_error
    end
  end
end


