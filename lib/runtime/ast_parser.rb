require 'parser/current'
require_relative '../model'
require_relative '../types'

module TypedRb

  class TermParsingError < TypeCheckError; end

  # Custom parser for type signatures.
  # It will transform the signature string into a hash
  # with the type information.
  class AstParser
    include Model

    def ast(ruby_code)
      Parser::CurrentRuby.parse(ruby_code)
    end

    def parse(expr)
      map(ast(expr), ParsingContext.new)
    end

    private

    def map(node, context)
      if node
        sexp = node.to_sexp
        sexp = "#{sexp[0..50]} ... #{sexp[-50..-1]}" if sexp.size > 100
        TypedRb.log(binding, :debug, "Parsing node #{node}:\n#{sexp}")
      end
      case node.type
      when :nil
        TmNil.new(node)
      when :module
        parse_module(node, context)
      when :class
        parse_class(node, context)
      when :def
        parse_def(node, context)
      when :defs
        parse_defs(node, context)
      when :ivar
        parse_instance_var(node, context)
      when :ivasgn
        parse_instance_var_assign(node, context)
      when :lvar
        TmVar.new(node.children.first, node)
      when :lvasgn
        parse_lvasgn(node, context)
      when :gvar
        parse_global_var(node, context)
      when :gvasgn
        parse_global_var_assign(node, context)
      when :masgn
        parse_mass_assign(node, context)
      when :begin, :kwbegin
        parse_begin(node, context)
      when :rescue
        parse_try(node, context)
      when :resbody
        parse_rescue(node, context)
      when :int
        TmInt.new(node)
      when :array
        parse_array_literal(node, context)
      when :hash
        parse_hash_literal(node, context)
      when :true, :false
        TmBoolean.new(node)
      when :str
        TmString.new(node)
      when :float
        TmFloat.new(node)
      when :sym
        TmSymbol.new(node)
      when :regexp
        parse_regexp(node, context)
      when :if
        parse_if_then_else(node, context)
      when :block
        parse_block(node, context)
      when :send
        parse_send(node, context)
      when :yield
        parse_yield(node, context)
      when :const
        TmConst.new(parse_const(node), node)
      when :casgn
        map(node.children.last, context)
      when :sclass
        parse_sclass(node, context)
      when :dstr
        parse_string_interpolation(node, context)
      when :dsym
        parse_symbol_interpolation(node, context)
      when :return
        parse_return(node, context)
      when :self
        parse_self(node, context)
      when :or
        parse_boolean_operation(:or, node, context)
      when :and
        parse_boolean_operation(:and, node, context)
      when :block_pass
        parse_block_pass(node, context)
      when :or_asgn, :and_asgn
        parse_boolean_asgn(node, context)
      else
        fail TermParsingError.new("Unknown term #{node.type}: #{node.to_sexp}", node)
      end
    end

    def parse_instance_var(node, _context)
      TmInstanceVar.new(node.children.first, node)
    end

    def parse_instance_var_assign(node, context)
      ivar = TmInstanceVar.new(node.children.first, node)
      TmInstanceVarAssignment.new(ivar, map(node.children.last, context), node)
    end

    def parse_global_var(node, _context)
      TmGlobalVar.new(node.children.first, node)
    end

    def parse_global_var_assign(node, context)
      gvar = TmGlobalVar.new(node.children.first, node)
      TmGlobalVarAssignment.new(gvar, map(node.children.last, context), node)
    end

    def parse_string_interpolation(node, context)
      units = node.children.map { |child| map(child, context) }
      TmStringInterpolation.new(units, node)
    end

    def parse_symbol_interpolation(node, context)
      units = node.children.map { |child| map(child, context) }
      TmSymbolInterpolation.new(units, node)
    end

    def parse_regexp(node, context)
      # ignore the regular expression options
      TmRegexp.new(map(node.children[0], context), nil, node)
    end

    def parse_block(node, context)
      if node.children[0].type == :send && node.children[0].children[1] == :lambda
        parse_lambda(node, context)
      elsif node.children[0].type == :send && node.children[0].children[0] && node.children[0].children[0].children[1] == :Proc
        parse_proc(node, context)
      else
        parse_send_block(node, context)
      end
    end

    def parse_block_pass(node, context)
      passed = if node.children.first.type == :sym
                 symbol = node.children.first.children.first
                 map(ast("Proc.new { |obj| obj.#{symbol} }"), context)
               else
                 map(node.children.first, context)
               end
      [:block_pass, passed]
    end

    def parse_send_block(node, context)
      block = parse_lambda(node, context)
      send = parse_send(node.children[0], context)
      send.with_block(block)
      send
    end

    def parse_lambda(node, context)
      args, body  = node.children[1], node.children[2]
      if args.type != :args
        fail Types::TypeParsingError.new("Error parsing function args [#{args}]", node)
      end
      args = parse_args(args.children, context, node)
      body = map(body, context)

      # TODO: deal with abs with a provided type, like block passed to typed functions.
      TmAbs.new(args,
                body,
                :lambda, # no type for the lambda so far.
                node)
    end

    def parse_proc(node, context)
      args = node.children[1]
      body = node.children[2]
      if args.type != :args
        fail Types::TypeParsingError.new("Error parsing function args [#{args}]", node)
      end
      args = parse_args(args.children, context, node)
      body = map(body, context)

      # TODO: deal with abs with a provided type, like block passed to typed functions.
      TmAbs.new(args,
                body,
                :proc, # no type for the lambda so far.
                node)
    end

    def parse_lvasgn(node, context)
      lhs, rhs = node.children
      TmLocalVarAsgn.new(lhs.to_s, map(rhs, context), node)
    end

    def parse_mass_assign(node, context)
      # each children is a :lvasgn
      lhs = node.children.first.children
      rhs = map(node.children.last, context)
      TmMassAsgn.new(lhs, rhs, node)
    end

    def parse_args(args, context, node)
      args.map do |arg|
        case arg.type
        when :arg
          [:arg, arg.children.last]
        when :optarg
          [:optarg, arg.children.first, map(arg.children.last, context)]
        when :blockarg
          [:blockarg, arg.children.first]
        when :restarg
          [:restarg, arg.children.last]
        else
          fail Types::TypeParsingError.new("Unknown type of arg '#{arg.type}'", node)
        end
      end
    end

    def parse_send(node, context)
      children = node.children
      receiver_node = children[0]
      receiver = receiver_node.nil? ? receiver_node : map(receiver_node, context)
      message = children[1]
      args = (children.drop(2) || []).map { |arg| map(arg, context) }
      build_send_message(receiver, message, args, node, context)
    end

    def build_send_message(receiver, message, args, node, context)
      if message == :typesig
      # ignore
      else
        if receiver.nil? && (message == :fail || message == :raise)
          TmError.new(node)
        else
          if args.last.is_a?(Array) && args.last.first == :block_pass
            block_pass = args.pop
            tm_send = TmSend.new(receiver, message, args, node)
            tm_send.with_block(block_pass.last)
            tm_send
          else
            TmSend.new(receiver, message, args, node)
          end
        end
      end
    end

    def parse_yield(node, context)
      args = node.children
      TmSend.new(nil, :yield, args.map { |arg| map(arg,context) }, node)
    end

    def parse_module(node, context)
      module_name = parse_const(node.children[0])
      context.with_type([:module, module_name]) do
        module_body = if node.children[1]
                       map(node.children[1], context)
                     else
                       nil
                     end
        TmModule.new(context.path_name, module_body, node)
      end
    end

    def parse_class(node, context)
      fail Types::TypeParsingError.new("Nil value parsing class") if node.nil? # No explicit class -> Object by default
      class_name = parse_const(node.children[0])
      super_class_name = parse_const(node.children[1]) || 'Object'
      context.with_type([:class, class_name, super_class_name]) do
        class_body = if node.children[2]
                       map(node.children[2], context)
                     else
                       nil
                     end
        TmClass.new(context.path_name, super_class_name, class_body, node)
      end
    end

    def parse_sclass(node, context)
      class_name = if node.children[0].type == :self
                     :self
                   else
                     parse_const(node.children[0])
                   end
      context.with_type([:self, class_name]) do
        class_body = map(node.children[1], context)
        TmSClass.new(class_name, class_body, node)
      end
    end

    def parse_const(const_node, accum = [])
      return nil if const_node.nil?
      accum << const_node.children.last
      if const_node.children.first.nil?
        accum.reverse.join('::')
      else
        parse_const(const_node.children.first, accum)
      end
    end

    def parse_def(node, context)
      fun_name, args, body = node.children
      owner = if context.singleton_class?
                :self
              else
                nil
              end
      parse_fun(owner, fun_name, args, body, node, context)
    end

    def parse_defs(node, context)
      owner, fun_name, args, body = node.children
      parse_fun(owner, fun_name, args, body, node, context)
    end

    def parse_fun(owner, fun_name, args, body, node, context)
      if args.type != :args
        fail Types::TypeParsingError.new("Error parsing function args [#{args}]", node)
      end
      # parse the owner of the function
      owner = if owner.nil? || owner == :self
                owner
              elsif owner.type == :const
                TmConst.new(parse_const(owner), node)
              elsif owner.type == :self
                owner
              else
                map(owner, context)
              end
      tm_body = if body.nil?
                  TmNil.new(node)
                else
                  map(body, context)
                end
      parsed_args = parse_args(args.children, context, node)
      TmFun.new(owner, fun_name, parsed_args, tm_body, node)
    end

    def parse_if_then_else(node, context)
      cond_expr, then_expr, else_expr = node.children
      then_expr_term = then_expr.nil? ? then_expr : map(then_expr, context)
      else_expr_term = else_expr.nil? ? else_expr : map(else_expr, context)
      TmIfElse.new(node,
                   map(cond_expr, context),
                   then_expr_term,
                   else_expr_term)
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

    def parse_array_literal(node, context)
      TmArrayLiteral.new(node.children.map do |child|
                           map(child, context)
                         end, node)
    end

    def parse_hash_literal(node, context)
      pairs = node.children.map do |pair|
        [map(pair.children.first, context), map(pair.children.last, context)]
      end
      TmHashLiteral.new(pairs, node)
    end

    def parse_return(node, context)
      elements = node.children.map { |element| map(element, context) }
      TmReturn.new(elements, node)
    end

    def parse_self(node, context)
      TmSelf.new(node)
    end

    def parse_boolean_operation(operation, node, context)
      TmBooleanOperator.new(operation,
                            map(node.children.first, context),
                            map(node.children.last, context),
                            node)
    end

    def parse_boolean_asgn(node, context)
      lhs = node.children.first
      rhs = map(node.children.last, context)
      case lhs.type
      when :ivasgn
        ivar = TmInstanceVar.new(lhs.children.first, lhs)
        TmBooleanOperator.new(:or, ivar, TmInstanceVarAssignment.new(ivar, rhs, node), node)
      when :gvasgn
        gvar = TmGlobalVar.new(lhs.children.first, lhs)
        TmBooleanOperator.new(:or, gvar, TmGlobalVarAssignment.new(gvar, rhs, node), node)
      when :lvasgn
        TmLocalVarAsgn.new(lhs.children.first.to_s, rhs, node)
      when :send
        receiver = map(lhs.children.first, context)
        message = lhs.children.last
        attr_reader = build_send_message(receiver, message, [], lhs, context)
        attr_writer = build_send_message(receiver, "#{message}=", [rhs], lhs, context)
        TmBooleanOperator.new(:or, attr_reader, attr_writer, node)
      end
    end
  end
end
