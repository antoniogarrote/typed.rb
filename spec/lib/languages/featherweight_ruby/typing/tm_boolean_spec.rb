require_relative '../spec_helper'

describe TypedRb::Languages::FeatherweightRuby::Model::TmBoolean do

  before :each do
    ::BasicObject::TypeRegistry.registry.clear
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
    let(:code) {
      <<__CODE
       ts '#f / Boolean -> Boolean'
       def f(b)
          b
       end

       f(true)
       f(false)
__CODE
    }

    it 'should be possible to type check a method and method application' do
      expect {
        ast.check_type(TypedRb::Languages::FeatherweightRuby::Types::TypingContext.top_level)
      }.to_not raise_error
    end
  end

  context 'when used as a subtype' do
    let(:code) {
      <<__CODE
       ts '#f / Object -> Object'
       def f(b)
          b
       end

       f(true)
       f(false)
__CODE
    }

    it 'should be possible to type check method application' do
      expect {
        ast.check_type(TypedRb::Languages::FeatherweightRuby::Types::TypingContext.top_level)
      }.to_not raise_error
    end
  end
end
