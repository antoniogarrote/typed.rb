require_relative '../../spec_helper'

describe TypedRb::Runtime::Normalization::Validations do

  let(:language) { TypedRb::Language.new }

  include described_class

  describe '#validate_signature' do
    it 'is valid if the type is a variable' do
      expect {
        validate_signature(:class_variable, nil)
      }.to_not raise_error
      expect {
        validate_signature(:instance_variable, nil)
      }.to_not raise_error
      expect {
        validate_signature(:invalid, nil)
      }.to raise_error(::TypedRb::Types::TypeParsingError)
    end
  end

  describe '#validate_signatures' do
    it 'raises an exception if there is a duplicated arity' do
      code = <<__END
      class TA
        ts '#x / Integer -> Integer -> Integer'
        ts '#x / String -> String -> String'
        def x(a,b); a + b; end
      end
__END
      expect {
        language.check(code)
      }.to raise_error(::TypedRb::Types::TypeParsingError)
    end
  end

  describe '#validate_method' do
    it 'fails if the class method info passed does not include the method validated' do
      expect {
        validate_method({instance_methods: []}, :class, :test, :instance)
      }.to raise_error(::TypedRb::Types::TypeParsingError)
      expect {
        validate_method({all_methods: []}, :class, :test, :class)
      }.to raise_error(::TypedRb::Types::TypeParsingError)
    end
  end

  describe '#validate_function_signature' do
    it 'fails if a hash is passed' do
      expect {
        validate_function_signature(nil, nil, {}, nil)
      }.to raise_error(::TypedRb::Types::TypeParsingError)
    end
  end
end