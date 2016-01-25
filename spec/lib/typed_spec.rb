require_relative '../spec_helper'

describe TypedRb do

  describe '#log_dynamic_warning' do
    it 'stores a warning if the :dynamic_warnings flag is enabled' do
      TypedRb.options = {:dynamic_warnings => true }
      TypedRb.dynamic_warnings.clear
      TypedRb.log_dynamic_warning(nil, nil, nil)
      expect(TypedRb.dynamic_warnings.count).to eq(1)

      TypedRb.options = {}
      TypedRb.dynamic_warnings.clear
      TypedRb.log_dynamic_warning(nil, nil, nil)
      expect(TypedRb.dynamic_warnings.count).to eq(0)
    end
  end

end