require_relative '../../spec_helper'

describe TypedRb::Model::TmWhile do
  let(:language) { TypedRb::Language.new }

  it 'type checks a simple while statement' do
    code = <<__CODE
      while false
        1 - 1
        1 + 1
      end
__CODE

    parsed = language.check(code)
    expect(parsed.ruby_type).to eq(Integer)
  end

  it 'type checks a simple post-while statement' do
    code = <<__CODE
      begin
        1 - 1
        1 + 1
      end while false
__CODE

    parsed = language.check(code)
    expect(parsed.ruby_type).to eq(Integer)
  end

  it 'type checks a simple until statement' do
    code = <<__CODE
      until true
        1 - 1
        1 + 1
      end
__CODE

    parsed = language.check(code)
    expect(parsed.ruby_type).to eq(Integer)
  end

  it 'type checks a simple post-until statement' do
    code = <<__CODE
      begin
        1 - 1
        1 + 1
      end until true
__CODE

    parsed = language.check(code)
    expect(parsed.ruby_type).to eq(Integer)
  end

  it 'type checks a while statement without body' do
    code = <<__CODE
      while false
      end
__CODE

    parsed = language.check(code)
    expect(parsed.ruby_type).to eq(NilClass)
  end

  it 'type checks a break statement in a while loop' do
    code = <<__CODE
      ts '#test_while_next / -> Integer'
      def test_while_next
        a = while(true) do
              next(7)
            end

        a + 10
      end
__CODE

    parsed = language.check(code)
    expect(parsed.to_s).to eq('( -> Integer)')
  end

  context 'with a either type' do
    it 'type checks the while loop correctly, positive case' do
      code = <<__CODE
      ts '#test_while_next / -> Integer'
      def test_while_next
        a = while(true) do
              if(false)
                1
              else
                next 0
              end
            end

        a + 10
      end
__CODE

      parsed = language.check(code)
      expect(parsed.to_s).to eq('( -> Integer)')
    end

    it 'type checks the while loop correctly, negative case' do
      code = <<__CODE
      ts '#test_while_next / -> Integer'
      def test_while_next
        while(true) do
          if(false)
            1
          else
            next false
          end
        end
      end
__CODE

      expect {
        language.check(code)
      }.to raise_error(TypedRb::TypeCheckError)
    end

    it 'type checks the while loop correctly with a return, positive case' do
      code = <<__CODE
      ts '#test_while_next / -> Integer'
      def test_while_next
        while(true) do
          if (false)
            1
          elsif (true)
            return 2
          else
            next 0
          end
        end
      end
__CODE


      parsed = language.check(code)
      expect(parsed.to_s).to eq('( -> Integer)')
    end
  end
end
