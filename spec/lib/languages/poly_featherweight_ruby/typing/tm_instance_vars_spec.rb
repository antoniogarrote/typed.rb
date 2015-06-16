require_relative '../spec_helper'

describe TypedRb::Languages::PolyFeatherweightRuby::Model::TmInstanceVar do

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
    TypedRb::Languages::PolyFeatherweightRuby::Model::GenSym.reset
    parser = TypedRb::Languages::PolyFeatherweightRuby::Parser.new
    parser.parse(typed_code)
  end

  context 'with invalid type assignment' do
    it 'should raise a type error' do
      expect {
        ast.check_type(TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.new)
      }.to raise_error(TypedRb::Languages::PolyFeatherweightRuby::Types::UncomparableTypes)
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
        ast.check_type(TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.new)
      }.to_not raise_error
    end
  end

  context 'with a valid singleton class instance variable' do
    let(:code) do
      <<__CODE
        class A
          ts '.@a / Integer'

          ts 'A.a / -> Integer'
          def self.a
            @a
          end
        end

        A.a
__CODE
    end

    it 'should not raise a type error' do
      expect {
        result = ast.check_type(TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.new)
        expect(result.to_s).to eq('Integer')
      }.to_not raise_error
    end
  end

  context 'with an invalid type annotation' do
    let(:code) do
      <<__CODE
        class A
          ts '.@a / Integer'

          ts 'A.a / -> String'
          def self.a
            @a
          end
        end

        A.a
__CODE
    end

    it 'should raise a type error' do
      expect {
        result = ast.check_type(TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.new)
      }.to raise_error(TypedRb::Languages::PolyFeatherweightRuby::Types::UncomparableTypes)
    end
  end
end
