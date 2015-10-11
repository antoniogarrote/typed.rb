module TypedRb
  module Types
    class TyFunction < Type
      attr_accessor :from, :to, :parameters_info, :block_type, :arity
      attr_writer :name

      def initialize(from, to, parameters_info = nil, node = nil)
        super(node)
        @from            = from.is_a?(Array) ? from : [from]
        @to              = to
        @parameters_info = parameters_info
        if @parameters_info.nil?
          @parameters_info = @from.map { |type| [:req, type] }
        end
        @arity           = parse_function_arity
        @block_type      = nil
      end

      def with_block_type(type)
        @block_type = type
        self
      end

      def arg_compatible?(num_args)
        if arity == Float::INFINITY
          true
        else
          arity == num_args
        end
      end

      def generic?
        false
      end

      def dynamic?
        false
      end

      def parse_function_arity
        return Float::INFINITY if parameters_info.detect{ |arg| arg.is_a?(Hash) && arg[:kind] == :rest }
        parameters_info.reject { |arg| arg.is_a?(Hash) && arg[:kind] == :block_arg }.count
      end

      def to_s
        args = @from.map(&:to_s).join(', ')
        args = "#{args}, &#{block_type.to_s}" if block_type
        "(#{args} -> #{@to})"
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

      def apply_bindings(bindings_map)
        from.each_with_index do |from_type, i|
          if from_type.is_a?(Polymorphism::TypeVariable)
            from_type.apply_bindings(bindings_map)
            from[i] = from_type.bound if from_type.bound
          elsif from_type.is_a?(TyGenericSingletonObject) || from_type.is_a?(TyGenericObject)
            from_type.apply_bindings(bindings_map)
          end
        end

        if to.is_a?(Polymorphism::TypeVariable)
          @to = to.apply_bindings(bindings_map)
          @to = to.bound if to.bound
        elsif to.is_a?(TyGenericSingletonObject) || to.is_a?(TyGenericObject)
          @to = to.apply_bindings(bindings_map)
        end

        block_type.apply_bindings(bindings_map) if block_type && block_type.generic?
        self
      end
    end

    class TyGenericFunction < TyFunction
      attr_accessor :local_typing_context

      def initialize(from, to, parameters_info = nil, node = nil)
        super(from, to, parameters_info, node)
        @application_count = 0
      end

      def generic?
        true
      end

      # Creates a new instance of a generic function with fresh type variables.
      # Yields the function so new constraints can be added.
      # Finally, it runs unification on the function typing context and returns
      # the materialized function with the bound variables.
      def materialize
        TypedRb.log binding, :debug, "Materialising function '#{self}'"

        # TODO: replace all this logic by a single invocation to .dup
        if @local_typing_context.nil?
          fail TypeCheckError.new("Type error checking function '#{name}': Cannot materialize function because of  missing local typing context")
        end
        local_parent_typing_context = @local_typing_context.parent
        @local_typing_context.parent = nil
        @local_typing_context = Marshal::load(Marshal.dump(@local_typing_context))
        @local_typing_context.parent = local_parent_typing_context
        materialized_from_args = []
        materialized_to_arg = nil

        @application_count += 1
        substitutions = @local_typing_context.local_var_types.each_with_object({}) do |var_type, acc|
          #acc[var_type.variable] = Polymorphism::TypeVariable.new("#{var_type}_#{@application_count}", :node => node)
          acc[var_type.variable] = Polymorphism::TypeVariable.new(var_type.variable, :node => node, :gen_name => false)
          acc[var_type.variable].upper_bound = var_type.upper_bound
          acc[var_type.variable].lower_bound = var_type.lower_bound
          # new fro/to args for the materialized function
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

        # var types coming from a generic method, not a generic type
        from.each_with_index do |from_var, i|
          materialized_from_arg = materialized_from_args[i]
          if materialized_from_arg.nil?
            materialized_from_args[i] = if from_var.is_a?(Polymorphism::TypeVariable)
                                          Polymorphism::TypeVariable.new(from_var.name,
                                                                         :upper_bound => from_var.upper_bound,
                                                                         :lower_bound => from_var.lower_bound,
                                                                         :bound => from_var.bound,
                                                                         :gen_name => false)
                                        else
                                          from_var
                                        end
          end
        end

        if materialized_to_arg.nil?
          materialized_to_arg = if to.is_a?(Polymorphism::TypeVariable)
                                  Polymorphism::TypeVariable.new(to.name,
                                                                 :upper_bound => to.upper_bound,
                                                                 :lower_bound => to.lower_bound,
                                                                 :bound => to.bound,
                                                                 :gen_name => false)
                                else
                                  to
                                end
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
          # Adding constraints for the generic vriables in the materialised function
          yield materialized_function
        end
        # got all the constraints here
        # do something with the context -> unification? merge context?
        unification = Polymorphism::Unification.new(applied_typing_context.all_constraints).run

        materialized_function.apply_bindings(unification.bindings_map)
      end

      def free_type_variables(klass)
        return type_variables if klass == :main
        class_type = Runtime::TypeParser.parse_singleton_object_type(klass.name)
        if class_type.generic?
          type_variables.reject do |type_var|
            class_type.type_vars.detect{ |class_type_var| class_type_var.variable == type_var.variable }
          end
        else
          type_variables
        end
      end

      def type_variables
        vars = (from + [ to ]).map do |arg|
          if arg.is_a?(Polymorphism::TypeVariable)
            arg
          elsif arg.generic?
            arg.type_vars
          else
            nil
          end
        end
        vars = vars.flatten.compact

        if block_type && block_type.generic?
          vars += block_type.type_variables
        end

        vars.uniq
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
