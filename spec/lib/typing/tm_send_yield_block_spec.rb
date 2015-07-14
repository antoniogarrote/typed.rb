require_relative '../../spec_helper'

describe TypedRb::Model::TmSend do
  let(:language) { TypedRb::Language.new }

  context 'with a yield blocking function' do
    it 'type-checks correctly the block yielding and the block passing' do
      expr = <<__END
     ts '#wblock / Integer -> &(Integer -> Integer) -> Integer'
     def wblock(x)
       yield x
     end

     wblock(2) { |n| n + 1 }
__END

      result = language.check(expr)
      expect(result).to eq(tyinteger)
    end

    it 'type-checks correctly errors in the block arguments application' do
      expr = <<__END
     ts '#wblock / Integer -> &(Integer -> Integer) -> Integer'
     def wblock(x)
       yield x
     end
     lambda {
       wblock('2') { |n| n + 1 }
     }
__END

      expect {
        language.check(expr)
      }.to raise_error(TypedRb::TypeCheckError)
    end

    it 'type-checks correctly errors in the block arguments type' do
      expr = <<__END
     class Integer
       ts '#+ / Integer -> Integer'
     end

     ts '#wblock / Integer -> &(Integer -> Integer) -> Integer'
     def wblock(x)
       yield x
     end
     lambda {
       wblock(2) { |n| n + '1' }
     }
__END

      expect {
        language.check(expr)
      }.to raise_error(TypedRb::TypeCheckError)
    end

    it 'type-checks correctly errors in the block return type' do
      expr = <<__END
     ts '#wblock / Integer -> &(Integer -> Integer) -> Integer'
     def wblock(x)
       yield x
     end

     wblock(2) { |n| '1' }
__END

      expect {
        language.check(expr)
      }.to raise_error(TypedRb::TypeCheckError)
    end
  end
end
