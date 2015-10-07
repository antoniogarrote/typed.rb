require_relative '../model'

module TypedRb
  module Model
    # abstraction
    class TmAbs < Expr
      attr_accessor :args, :term, :arity, :abs_type
      def initialize(args, term, abs_type, node)
        super(node, type)
        @args     = args
        @term     = term
        @abs_type = abs_type
        @arity    = args.select { |(arg_type, _, _)|  arg_type == :arg }.count
        @instantiation_count = 0
      end

      def rename(from_binding, to_binding)
        unless args.any? { |(_type, arg_value)| arg_value.to_s == from_binding.to_s }
          term.rename(from_binding, to_binding)
        end
        self
      end

      def check_type(context)
        with_fresh_bindings(context) do |var_type_args, var_type_return, context|
          type_term = term.check_type(context)
          if var_type_return.compatible?(type_term, :gt)
            Types::TyGenericFunction.new(var_type_args, var_type_return, resolve_ruby_method_parameters, node)
          else
            # TODO: improve message
            error_msg = "Error parsing abstraction, incompatible return type found: #{var_type_return} < #{type_term}"
            fail TypeCheckError.new(error_msg, node)
          end
        end
      end

      # abstractions are polymorphic universal types by default,
      # we need new bindings in the type variables with each instantiation of the lambda.
      def with_fresh_bindings(context)
        orig_context = Types::TypingContext.type_variables_register
        Types::TypingContext.push_context(:lambda)
        fresh_args = args.map do |(type, var, opt)|
          if type == :mlhs
            context = var.check_type(:lambda, context)
            var
          else
            type_var_arg = Types::TypingContext.type_variable_for_abstraction(:lambda, "#{var}", context)
            type_var_arg.node = node
            context = case type
                      when :arg, :block
                        context.add_binding(var, type_var_arg)
                      when :optarg
                        declared_arg_type = opt.check_type(orig_context)
                        if type_var_arg.compatible?(declared_arg_type, :gt)
                          context.add_binding(var, type_var_arg)
                        end
                      end
            type_var_arg
          end
        end

        return_type_var_arg = Types::TypingContext.type_variable_for_abstraction(:lambda, nil, context)
        return_type_var_arg.node = node
        lambda_type  = yield fresh_args, return_type_var_arg, context
        lambda_type.local_typing_context = Types::TypingContext.pop_context
        lambda_type
      end

      protected

      def resolve_ruby_method_parameters
        args.map do |(arg_type, val, _)|
          if arg_type == :optarg
            [:opt, val]
          elsif arg_type == :blockarg
            [:block, val]
          else
            [:req, val]
          end
        end
      end
    end
  end
end
