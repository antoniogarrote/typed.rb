require_relative '../../parser_module'
require_relative 'model'
require_relative 'types'

module TypedRb
  module Languages
    module TypedLambdaCalculus

      class ParsingContext
        def initialize
          @types_stack = []
        end

        def type=(type)
          @types_stack << type
        end

        def type
          @types_stack.pop
        end
      end

      class Parser
        include ParserModule
        include Model

        def parse(expr)
          map(ast(expr),ParsingContext.new)
        end

        private

        def map(node, context)
          case node.type
          when :begin
            parse_begin(node, context)
          when :int
            TmInt.new(node)
          when :true,:false
            TmBoolean.new(node)
          when :str
            TmString.new(node)
          when :float
            TmFloat.new(node)
          when :if
            parse_if_then_else(node, context)
          when :lvasgn
            parse_let(node, context)
          when :block
            parse_lambda(node, context)
          when :send
            parse_send(node, context)
          when :lvar
            TmVar.new(node.children.first,node)
          else
            fail StandardError, "Unknown term #{node.type}: #{node}"
          end
        end

        def parse_lambda(node, context)
          args,body  = node.children[1],node.children[2]
          arg = parse_args(args, context)
          body = map(body, context)
          uniq_arg = Model::GenSym.next(arg)

          TmAbs.new(uniq_arg,
                    body.rename(arg, uniq_arg),
                    context.type,
                    node)
        end

        def parse_let(node, context)
          binding, term = node.children
          TmLet.new(binding, map(term,context), node)
        end

        def parse_args(args, _context)
          if args.type != :args || args.children.length != 1
            fail StandardError,"Error parsing lambda args [#{args}]"
          end
          args.children.first.children.first.to_s
        end

        def parse_send(node, context)
          receiver, message, content = node.children
          if message == :typesig
            parse_type(node, context)
          else
            if receiver.nil?
              TmVar.new(message,node)
            else
              TmApp.new(map(receiver, context),
                        map(content, context),
                        node)
            end
          end
        end

        def parse_if_then_else(node, context)
          cond_expr, then_expr, else_expr = node.children
          TmIfElse.new(node,
                       map(cond_expr, context),
                       map(then_expr, context),
                       map(else_expr, context))
        end

        def parse_begin(node, context)
          mapped = node.children.map do |child_node|
            map(child_node, context)
          end
          sequencing = TmSequencing.new(mapped,node)
          if sequencing.terms.size == 1
            sequencing.terms.first
          else
            sequencing
          end
        end

        def parse_type(node,context)
          # send -> hash
          signature = node.children[2]
          type_ast = TypedRb::TypeSignature::Parser.parse(signature.children.first.to_s)
          type = Types::Type.parse(type_ast)
          unless type.compatible?(Types::TyFunction)
            type = Types::TyFunction.new(type,nil)
          end
          context.type = type
          nil
        end
      end
    end
  end
end
