require_relative '../../spec_helper'

describe 'boolean assign operations' do
  let(:language) { TypedRb::Language.new }

  context 'with instance level variables' do
    it 'type-checks boolean assignment operations' do
      expr = <<__END
        class BAsgn1
          ts '#test / -> Integer'
          def test
            @test ||= 1
          end
        end

        BAsgn1.new.test
__END

      result = language.check(expr)
      expect(result.ruby_type).to eq(Integer)
    end

    it 'detects type errors' do

      expr = <<__END
        class BAsgn1
          ts '#test / -> String'
          def test
            @test = 1
            @test ||= 'string'
          end
        end

        BAsgn1.new.test
__END

      expect {
        language.check(expr)
      }.to raise_error(TypedRb::Types::Polymorphism::UnificationError)
    end
  end

  context 'with global variables' do
    it 'type-checks boolean assignment operations' do
      expr = <<__END
        $VAR_BASGN ||= 3
        $VAR_BASGN
__END

      result = language.check(expr)
      expect(result.bound.ruby_type).to eq(Integer)
    end

    it 'type-checks boolean && assignment operations' do

      expr = <<__END
        $VAR_BASGN = 3
        $VAR_BASGN &&= Numeric.new
__END

      result = language.check(expr)
      expect(result.bound.ruby_type).to eq(Numeric)
    end
  end

  context 'with local variables' do
    it 'type-checks boolean assignment operations' do
      expr = <<__END
        var ||= 3
        var
__END
      result = language.check(expr)
      expect(result.ruby_type).to eq(Integer)
    end

    it 'detects type errors' do
      expr = <<__END
        var ||= 3
        var = Numeric.new
        var
__END
      expect {
        language.check(expr)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context 'with attr_readers/attr_writers' do
    it 'type-checks boolean assignment operations' do
      expr = <<__END
        class BAsgn2
          ts '#t / -> Integer'
          def t
           @t
          end

          ts '#t= / Integer -> Integer'
          def t=(t)
           @t = t
          end
        end

        ba2 = BAsgn2.new

        ba2.t ||= 3
__END
      result = language.check(expr)
      expect(result.ruby_type).to eq(Integer)
    end

    it 'detects type errors' do
      expr = <<__END
        class BAsgn3
          ts '#t / -> String'
          def t
           @t
          end

          ts '#t= / Integer -> Integer'
          def t=(t)
           @t = t
          end
        end

        ba3 = BAsgn3.new

        ba3.t ||= 3
__END
      expect {
        language.check(expr)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end
end
