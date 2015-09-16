require_relative '../../spec_helper'

describe TypedRb::Model::TmSend do
  let(:language) { TypedRb::Language.new }

  context 'with a yield blocking function' do
    it 'type-checks correctly the block yielding and the block passing' do
      expr = <<__END
     ts '#wblock1 / Integer -> &(Integer -> Integer) -> Integer'
     def wblock1(x)
       yield x
     end

     wblock1(2) { |n| n + 1 }
__END

      result = language.check(expr)
      expect(result).to eq(tyinteger)
    end

    it 'type-checks correctly errors in the block arguments application' do
      expr = <<__END
     ts '#wblock2 / Integer -> &(Integer -> Integer) -> Integer'
     def wblock2(x)
       yield x
     end
     lambda {
       wblock2('2') { |n| n + 1 }
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

     ts '#wblock3 / Integer -> &(Integer -> Integer) -> Integer'
     def wblock3(x)
       yield x
     end
     lambda {
       wblock3(2) { |n| n + '1' }
     }
__END

      expect {
        language.check(expr)
      }.to raise_error(TypedRb::TypeCheckError)
    end

    it 'type-checks correctly errors in the block return type' do
      expr = <<__END
     ts '#wblock4 / Integer -> &(Integer -> Integer) -> Integer'
     def wblock4(x)
       yield x
     end

     wblock4(2) { |n| '1' }
__END

      expect {
        language.check(expr)
      }.to raise_error(TypedRb::TypeCheckError)
    end

    it 'type-checks block-passing args' do
      expr = <<__CODE

        ts '#f / &(Integer -> String) -> String'
        def f(&b)
          b[1]
        end

        p = Proc.new { |arg| 'string' }

        f(&p)
__CODE

      result = language.check(expr)

      expect(result.ruby_type).to eq(String)
    end

    it 'captures errors type-checking block-passing args' do

      expr = <<__CODE

        ts '#f / &(Integer -> String) -> String'
        def f(&b)
          b[1]
        end

        p = Proc.new { |arg| 0 }

        f(&p)
__CODE

      expect {
        language.check(expr)
      }.to raise_error(TypedRb::Types::UncomparableTypes)

    end

    it 'captures errors type-checking block-passing args' do

      expr = <<__CODE

        ts '#f / &(Integer -> String) -> Integer'
        def f(&b)
          b[1]
        end

        p = Proc.new { |arg| 'string' }

        f(&p)
__CODE

      expect {
        language.check(expr)
      }.to raise_error(TypedRb::Types::UncomparableTypes)

    end

    it 'type-checks yielded block-passing args' do
      expr = <<__CODE

        ts '#f / &(Integer -> String) -> String'
        def f(&b)
          yield 1
        end

        p = Proc.new { |arg| 'string' }

        f(&p)
__CODE

      result = language.check(expr)

      expect(result.ruby_type).to eq(String)
    end

    it 'type-checks yielded blocks' do
      expr = <<__CODE

        ts '#f / &(Integer -> String) -> String'
        def f(&b)
          yield 1
        end

        f { |arg| 'string' }
__CODE

      result = language.check(expr)

      expect(result.ruby_type).to eq(String)
    end

    it 'captures errors in yielded type-checking block-passing args' do

      expr = <<__CODE

        ts '#f / &(Integer -> String) -> String'
        def f(&b)
          yield 1
        end

        p = Proc.new { |arg| 0 }

        f(&p)
__CODE

      expect {
        language.check(expr)
      }.to raise_error(TypedRb::Types::UncomparableTypes)

    end

    it 'captures errors in yielded type-checking blocks' do

      expr = <<__CODE

        ts '#f / &(Integer -> String) -> String'
        def f(&b)
          yield 1
        end

        f { |arg| 0 }
__CODE

      expect {
        language.check(expr)
      }.to raise_error(TypedRb::Types::UncomparableTypes)

    end

    it 'captures errors yielded type-checking block-passing args' do

      expr = <<__CODE

        ts '#f / &(Integer -> String) -> Integer'
        def f(&b)
          yield 1
        end

        p = Proc.new { |arg| 'string' }

        f(&p)
__CODE

      expect {
        language.check(expr)
      }.to raise_error(TypedRb::Types::UncomparableTypes)

    end

    it 'type-checks symbol.to_proc converted arguments' do
      expr = <<__CODE
        class TStP1
          ts '#test / -> String'
          def test
            'string'
          end
        end

        ts '#ftstp1 / TStP1 -> &(TStP1 -> String) -> String'
        def ftstp1(obj, &b)
          yield obj
        end

        ftstp1(TStP1.new, &:test)
__CODE

      # TODO: the correct signature for this method would be #ftstp1 / [T] -> &([T] -> String) -> String
      # but we don't have generic methods yet
      result = language.check(expr)
      expect(result.ruby_type).to eq(String)
    end

    it 'captures errors in the application of  symbol.to_proc converted arguments' do
      expr = <<__CODE
        class TStP2
          ts '#test / -> String'
          def test
            'string'
          end
        end

        ts '#ftstp2 / TStP2 -> &(TStP2 -> Integer) -> Integer'
        def ftstp2(obj, &b)
          yield obj
        end

        ftstp2(TStP2.new, &:test)
__CODE

      expect {
        language.check(expr)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end

    # TODO: Check for a generic class, see TODO above.
  end
end
