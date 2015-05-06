require_relative '../../parser_module'
require_relative './parser'

module TypedRb
  module Languages
    # A simple module for arithmetic expressions
    module ArithmeticExpressions
      class Language
        def eval(expr)
          Parser.new.parse(expr).eval
        end
      end
    end
  end
end
