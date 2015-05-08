require_relative './parser'

module TypedRb
  module Languages
    module UntypedLambdaCalculus
      class Language
        include Model

        def parse(expr)
          parser = Parser.new
          ast = parser.parse(expr)
          parser.remove_names(ast).first
        end

        def eval(expr)
          parser = Parser.new
          ast = parser.parse(expr)
          ast = parser.remove_names(ast).first
          #binding.pry
          ast.eval
        end

      end
    end
  end
end
