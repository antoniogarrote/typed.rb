require_relative '../../spec_helper'

describe ':break term' do
  let(:language) { TypedRb::Language.new }

  xit 'is type checked as unit type' do
    code = <<__END
     break
__END
  end
end
