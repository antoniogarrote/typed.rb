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

        def remove_names(ast, context = {})
          case ast.class
          when TmVar
            if context[ast.val]
              ast.index = context[ast.val]
            else
              context[ast.val] = context.keys.length + 1
              ast.index = context[ast.val]
            end
          when TmApp
            _, context_abs = remove_names(ast.abs, context.dup)
            context_abs.each_pair do |key,val|
              context[key] = val if context[key].nil?
            end
            _, context = remove_names(ast.subs, context)
          when  TmAbs
            to_bind = ast.head
            if context[to_bind]
              fail StandardError.new, "Variable #{to_bind} captured, renamining not in place yet"
            else
              context.keys.each do |variable|
                context[variable] = context[variable] + 1
              end
              context[to_bind] = 0
            end
            remove_names(ast.term, context)
          else
            fail StandardError.new,"Unknown AST node #{ast}"
          end
          [ast,context]
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
          TmAbs.new(parse_args(args, context),
                    map(body, context),
                    context.type,
                    node)
        end

        def parse_args(args, context)
          if(args.type != :args || args.children.length != 1)
            fail StandardError,"Error parsing lambda args [#{args}]"
          end
          args.children.first.children.first
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
          end.reject(&:nil?)
          if mapped.size == 1
            mapped.first
          else
            mapped
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
