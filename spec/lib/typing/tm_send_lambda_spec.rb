require_relative '../../spec_helper'

describe TypedRb::Model::TmSend do
  let(:language) { TypedRb::Language.new }

  context 'with lambda functions' do
    it 'evaluates lambda functions applications' do
      expr = <<__END
     id = ->(x) { x }
     id[1]
__END

      result = language.check(expr)
      expect(result).to eq(tyinteger)

      expr = <<__END
     id = ->(x) { x }
     id[1]
     id['string']
__END

      result = language.check(expr)
      expect(result).to eq(tystring)
    end

    it 'evaluates lambda functions with either types' do
      expr = <<__END
      f = ->() do
          if(true)
            1.0
          else
            return 2
          end
      end
      f[]
__END
      result = language.check(expr)
      expect(result.to_s).to eq('Numeric')
    end

    xit 'evaluates lambda functions with either types including break type' do
      expr = <<__END
      f = ->() do
          if(true)
            1.0
          else
            break 2
          end
      end
      f[]
__END
      result = language.check(expr)
      expect(result.to_s).to eq('Numeric')
    end

    it 'evaluates lambda functions applications with message sending inside' do
      expr = <<__END
     class Integer
       ts '#+ / Integer -> Integer'
     end

     class String
       ts '#+ / String -> String'
     end

     add = ->(x,y) { x + y }
     add[1,2]
__END

      result = language.check(expr)
      expect(result).to eq(tyinteger)

      expr = <<__END
     class Integer
       ts '#+ / Integer -> Integer'
     end

     class String
       ts '#+ / String -> String'
     end

     add = ->(x,y) { x + y }
     add[1,2]
     add['hello','world']
__END

      result = language.check(expr)
      expect(result).to eq(tystring)

      expr = <<__END
     class Integer
       ts '#foo / Integer -> String'
       def foo(x); 'foo'; end
     end

     f = ->(x,y) { x.foo(y) }
     f[1,2]
__END

      result = language.check(expr)
      expect(result).to eq(tystring)

    end

    it 'catches expcetions in lambda applications' do

      expr = <<__END
     class Integer
       ts '#foo / String -> String'
       def foo(x); 'foo'; end
     end

     f = ->(x,y) { x.foo(y) }
     f[1,2]
__END
      expect {
        result = language.check(expr)
      }.to raise_error(TypedRb::TypeCheckError)

      expr = <<__END
     class Integer
       ts '#foo / String -> String'
       def foo(x); 'foo'; end
     end

     f = ->(x,y) { x.foo(y) }
     f[1,'bar']
__END
      result = language.check(expr)
      expect(result).to eq(tystring)
    end
  end
end
