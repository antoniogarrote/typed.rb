require_relative '../../parser_module'
require_relative 'model'
require_relative 'types'

module TypedRb
  module Languages
    module FeatherweightRuby

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
          when :class
            parse_class(node, context)
          when :def
            parse_def(node, context)
          when :defs
            parse_defs(node,context)
          when :begin, :kwbegin
            parse_begin(node, context)
          when :rescue
            parse_try(node, context)
          when :resbody
            parse_rescue(node, context)
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
          fail "Not implemented yet"
          args,body  = node.children[1],node.children[2]
          if args.type != :args
            fail StandardError,"Error parsing function args [#{args}]"
          end
          arg = parse_args(args.children, context)
          body = map(body, context)
          uniq_arg = Model::GenSym.next(arg)

          TmAbs.new(uniq_arg,
                    body.rename(arg, uniq_arg),
                    context.type,
                    node)
        end

        def parse_let(node, context)
          binding, term = node.children
          TmLet.new(binding.to_s, map(term,context), node)
        end

        def parse_args(args, context)
          args.map do |arg|
            case arg.type
            when :arg
              [:arg, arg.children.last]
            when :optarg
              [:optarg, arg.children.first, map(arg.children.last, context)]
            when :blockarg
              [:blockarg, arg.children.first]
            end
          end
        end

        def parse_send(node, context)
          children = node.children
          receiver = children[0]
          message = children[1]
          args = children.drop(2) || []
          if message == :typesig
            # ignore
          else
            if receiver.nil? && (message == :fail || message == :raise)
                TmError.new(node)
            else
              TmSend(map(receiver, context), message, parse_args(args, context), node)
            end
          end
        end

        def parse_class(node, context)
          class_description = parse_class_name(node.children[0])
          super_class_description = parse_class_name(node.children[1])
          class_body = map(node.children.last, context)
          TmClass.new(class_description, super_class_description, class_body, node)
        end

        def parse_class_name(class_node, accum = [])
          return 'Object' if class_node.nil? # No explicit class -> Object by default
          accum << class_node.children.last
          if class_node.children.first.nil?
            accum.reverse.join('::')
          else
            parse_class_name(class_node.children.first, accum)
          end
        end

        def parse_def(node, context)
          fun_name, args, body = node.children
          if args.type != :args
            fail StandardError,"Error parsing function args [#{args}]"
          end
          TmFun.new(nil, fun_name, parse_args(args.children, context), map(body, context), node)
        end

        def parse_defs(node, context)
          owner, fun_name, args, body = node.children
          if args.type != :args
            fail StandardError,"Error parsing function args [#{args}]"
          end
          TmFun.new(owner, fun_name, parse_args(args.children, context), map(body, context), node)
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

        def parse_try(node, context)
          try_term = map(node.children.first, context)
          rescue_terms = node.children.drop(1).compact.map{|term| map(term, context) }
          TmTry.new(try_term, rescue_terms, node)
        end

        def parse_rescue(node, context)
          rescue_body = node.children[2]
          if rescue_body.nil?
            nil
          else
            map(rescue_body, context)
          end
        end
      end
    end
  end
end
