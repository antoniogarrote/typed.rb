require_relative '../../parser_module'
require_relative 'model'

module TypedRb
  module Languages
    module ArithmeticExpressions
      # Parser for the language
      class Parser
        include ParserModule
        include Model

        # Parses one valid arithmetic expression
        # Returns an AST of arithmetic terms
        def parse(expr)
          map(ast(expr))
        end

        private

        def map(node)
          case node.type
          when :true
            TmTrue.new
          when :false
            TmFalse.new
          when :if
            map_if_then_else(node)
          when :int
            map_int(node)
          when :send
            map_function(node)
          else
            fail StandardError.new, "Unknown expression '#{node}'"
          end
        end

        def map_function(node)
          _, function_name, argument = node.children
          mapped_argument = map(argument)
          case function_name
          when :isZero
            TmIsZero.new(mapped_argument)
          when :pred
            TmPred.new(mapped_argument)
          when :succ
            TmSucc.new(mapped_argument)
          else
            fail StandardError.new, "Unknown function '#{function_name}'"
          end
        end

        def map_int(node)
          if node.children.first == 0
            TmZero.new
          else
            fail StandardError, "Unknown integer '#{node.children.first}'"
          end
        end

        def map_if_then_else(node)
          cond_expr, then_expr, else_expr = node.children
          TmIfElse.new(map(cond_expr),
                       map(then_expr),
                       map(else_expr))
        end
      end
    end
  end
end
