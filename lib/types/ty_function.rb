module TypedRb
  module Types
    class TyFunction < Type
      attr_accessor :from, :to, :parameters_info, :block_type
      attr_writer :name

      def initialize(from, to, parameters_info = nil, node = nil)
        super(node)
        @from            = from.is_a?(Array) ? from : [from]
        @to              = to
        @parameters_info = parameters_info
        @block_type      = nil
        if @parameters_info.nil?
          @parameters_info = @from.map { |type| [:req, type] }
        end
      end

      def with_block_type(type)
        @block_type = type
        self
      end

      def generic?
        false
      end

      def dynamic?
        false
      end

      def to_s
        "(#{@from.map(&:to_s).join(',')} -> #{@to})"
      end

      def name
        @name || "lambda"
      end

      def check_args_application(actual_arguments, context)
        parameters_info.each_with_index do |(require_info, arg_name), index|
          actual_argument = actual_arguments[index]
          from_type = from[index]
          if actual_argument.nil? && require_info != :opt
            error_msg = "Type error checking function '#{name}': Missing mandatory argument #{arg_name} in #{receiver_type}##{message}"
            fail TypeCheckError.new(error_msg, node)
          else
            unless actual_argument.nil? # opt if this is nil
              actual_argument_type = actual_argument.check_type(context)
              unless actual_argument_type.compatible?(from_type, :lt)
                error_message = "Type error checking function '#{name}': #{error_message} #{from_type} expected, #{argument_type} found"
                fail TypeCheckError.new(error_message, node)
              end
            end
          end
        end
        self
      end

      # (S1 -> S2) < (T1 -> T2) => T1 < S1 && S2 < T2
      # Contravariant in the input, covariant in the output
      def compatible?(other_type, relation = :lt)
        if other_type.is_a?(TyGenericFunction)
          other_type.compatible?(self, relation == :lt ? :gt : :lt)
        elsif other_type.is_a?(TyFunction)
          from.each_with_index do |arg, i|
            other_arg = other_type.from[i]
            unless arg.compatible?(other_arg, :gt)
              return false
            end
          end
          unless to.compatible?(other_type.to, :lt)
            return false
          end
        else
          fail TypeCheckError.new("Type error checking function '#{name}': Comparing function type with no function type")
        end

        return true
      end
    end

    class TyGenericFunction < TyFunction
      attr_accessor :local_typing_context

      def initialize(from, to, parameters_info = nil, node = nil)
        super(from, to, parameters_info, node)
        @local_typing_context = local_typing_context
        @application_count = 0
      end

      def generic?
        true
      end

      def materialize
        if @local_typing_context.nil?
          fail TypeCheckError.new("Type error checking function '#{name}': Cannot materialize function because of \
missing local typing context")
        end
        materialized_from_args = []
        materialized_to_arg = nil

        @application_count += 1
        substitutions = @local_typing_context.local_var_types.each_with_object({}) do |var_type, acc|
          acc[var_type.variable] = Polymorphism::TypeVariable.new("#{var_type}_#{@application_count}", :node => node)
          maybe_from_arg = from.detect do |from_var|
            from_var.is_a?(Polymorphism::TypeVariable) && from_var.variable == var_type.variable
          end
          if maybe_from_arg
            materialized_from_args[from.index(maybe_from_arg)] = acc[var_type.variable]
          end
          if to.is_a?(Polymorphism::TypeVariable) && to.variable == var_type.variable
            materialized_to_arg = acc[var_type.variable]
          end
        end

        if materialized_from_args.size != from.size
          error_msg = "Type error checking function '#{name}': Cannot find all the type variables for function \
application in the local typing context, expected #{from.size} got #{materialized_from_args.size}."
          fail TypeCheckError.new(error_msg, node)
        end

        if materialized_to_arg.nil?
          error_msg = "Type error checking function '#{name}': Cannot find the return type variable for function \
application in the local typing context."
          fail TypeCheckError.new(error_msg)
        end
        applied_typing_context = @local_typing_context.apply_type(@local_typing_context.parent, substitutions)
        materialized_function = TyFunction.new(materialized_from_args, materialized_to_arg, parameters_info, node)
        materialized_function.name = name
        if block_type
          block_materialized_from = block_type.from.map do |block_from_arg|
            if block_from_arg.is_a?(Polymorphism::TypeVariable)
              substitutions[block_from_arg.variable] || block_from_arg
            else
              block_from_arg
            end
          end
          block_materialized_to = if block_type.to.is_a?(Polymorphism::TypeVariable)
                                    substitutions[block_type.to.variable] || block_type.to
                                  else
                                    block_type.to
                                  end

          materialized_function.block_type = TyFunction.new(block_materialized_from,
                                                            block_materialized_to,
                                                            block_type.parameters_info,
                                                            block_type.node)
        end

        TypingContext.with_context(applied_typing_context) do
          yield materialized_function
        end

        # got all the constraints here
        # do something with the context -> unification? merge context?
        Polymorphism::Unification.new(applied_typing_context.all_constraints).run
        bound_from_args = materialized_function.from.map  { |arg| arg.bound || arg }
        bound_to_arg = materialized_function.to.bound || materialized_function.to
        #
        materialized_function = TyFunction.new(bound_from_args, bound_to_arg, parameters_info, node)
        materialized_function.name = name
        materialized_function
      end

      def free_type_variables(klass)
        class_type = Type.parse_singleton_object_type(klass.name)
        if class_type.generic?
          type_variables.reject do |type_var|
            class_type.type_vars.detect{ |class_type_var| class_type_var.variable == type_var.variable }
          end
        else
          type_variables
        end
      end

      def type_variables
        (from + [ to ]).select{ |arg| arg.is_a?(Polymorphism::TypeVariable) }
      end

      def check_args_application(actual_arguments, context)
        if @local_typing_context.kind != :lambda
          super(actual_arguments, context)
        else
          materialize do |materialized_function|
            materialized_function.check_args_application(actual_arguments, context)
          end
        end
      end

      def compatible?(other_type, relation = :lt)
        materialize do |materialized_function|
          materialized_function.compatible?(other_type, relation)
        end
      end
    end
  end
end
