require_relative '../../spec_helper'

describe TypedRb::Runtime::Normalization::Validations do
  include described_class
  describe '#validate_signature' do
    it 'is valid if the type is a variable' do
      expect {
        validate_signature(:class_variable, nil)
      }.to_not raise_error
      expect {
        validate_signature(:instance_variable, nil)
      }.to_not raise_error
    end
  end
end