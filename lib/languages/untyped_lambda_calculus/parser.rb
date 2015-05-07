require_relative '../../parser_module'
require_relative 'model'

module TypedRb
  module Languages
    module UntypedLambdaCalculus

      class Parser
        include ParserModule
        include Model

        def parse(expr)
          map(ast(expr))
        end

        def remove_names(ast, context = {})
          if ast.class == TmVar
            if context[ast.val]
              ast.index = context[ast.val]
            else
              context[ast.val] = context.keys.length + 1
              ast.index = context[ast.val]
            end
          elsif ast.class ==  TmApp
            _, context_abs = remove_names(ast.abs, context.dup)
            context_abs.each_pair do |key,val|
              context[key] = val if context[key].nil?
            end
            _, context = remove_names(ast.subs, context)
          elsif ast.class == TmAbs
            to_bind = ast.head
            if(context[to_bind])
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

        def map(node)
          case node.type
          when :block
            parse_lambda(node)
          when :send
            parse_send(node)
          when :lvar
            TmVar.new(node.children.first,node)
          else
            fail StandardError, "Unknown term #{node.type}: #{node}"
          end
        end

        def parse_lambda(node)
          args,body  = node.children[1],node.children[2]
          TmAbs.new(parse_args(args),map(body),node)
        end

        def parse_args(args)
          if(args.type != :args || args.children.length != 1)
            fail StandardError,"Error parsing lambda args [#{args}]"
          end
          args.children.first.children.first
        end

        def parse_send(node)
          receiver = node.children.first
          if receiver.nil?
            TmVar.new(node.children[1],node)
          else
            TmApp.new(map(node.children[0]),
                      map(node.children[2]),
                      node)
          end
        end
      end
    end
  end
end
