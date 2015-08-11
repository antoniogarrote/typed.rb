require_relative '../../spec_helper'

describe TypedRb::Model::TmConst do

  let(:language) { TypedRb::Language.new }

  it 'type checks class constants' do
    result = language.check('class TmConstTest1; end; TmConstTest1')
    expect(result.ruby_type).to eq(TmConstTest1)
  end

  it 'type checks module constants' do
    result = language.check('module TmConstTest2; end; TmConstTest2')
    expect(result.ruby_type).to eq(TmConstTest2)
  end

  it 'type checks user defined constants'
  # it 'type checks user defined constants' do
  #   code = <<__END
  #     module TestConstTest3
  #       MY_CONSTANT = 2
  #     end
  #
  #     TestConstTest3::MY_CONSTANT
#__END
  #   result = language.check(code)
  #   expect(result.ruby_type).to eq(Integer)
  # end
end
