require_relative 'spec_helper'

describe TypedRb::Languages::PolyFeatherweightRuby::Language do
  context 'with valid source code' do
    it 'should be possible to type check the code' do
      code = <<__CODE
class Integer
  ts '#+ / Integer -> Integer'
end
class Counter

  ts '#initialize / Integer -> unit'
  def initialize(start_value)
    @counter = start_value
  end

  ts '#inc / Integer -> Integer'
  def inc(num=1)
    @counter = @counter + num
  end

  ts '#counter / -> Integer'
  def counter
    @counter
  end
end
__CODE

      result = described_class.new.check(code)
      #TODO
      pending('Wire unification.')
    end
  end
end
