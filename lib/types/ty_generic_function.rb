module TypedRb
  module Types
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
        applied_typing_context, substitutions = create_context
        materialized_function = clone_with_substitutions(self, substitutions)
        TypingContext.with_context(applied_typing_context) do
          # Adding constraints for the generic vriables in the materialised function
          yield  materialized_function
        end
        # got all the constraints here
        # do something with the context -> unification? merge context?
        unification = Polymorphism::Unification.new(applied_typing_context.all_constraints).run
        applied_typing_context.unlink # these constraints have already been satisfied
        materialized_function.apply_bindings(unification.bindings_map)
      end

      def free_type_variables(klass)
        return type_variables if klass == :main
        class_type = Runtime::TypeParser.parse_singleton_object_type(klass.name)
        if class_type.generic?
          type_variables.reject do |type_var|
            class_type.type_vars.detect { |class_type_var| class_type_var.variable == type_var.variable }
          end
        else
          type_variables
        end
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

      protected

      def create_context
        @application_count += 1
        @local_typing_context.clone(:method)
      end

      def clone_with_substitutions(function, substitutions)
        # var types coming from a generic method, not a generic type will be nil
        materialized_from = function.from.map do |from_var|
          if from_var.is_a?(Polymorphism::TypeVariable)
            substitutions[from_var.variable] || from_var.clone
          elsif from_var.is_a?(TyGenericSingletonObject) || from_var.is_a?(TyGenericObject)
            from_var.send(:clone_with_substitutions, substitutions)
          else
            from_var
          end
        end
        to_var = function.to
        materialized_to = if to_var.is_a?(Polymorphism::TypeVariable)
                            substitutions[to_var.variable] || to_var.clone
                          elsif to_var.is_a?(TyGenericSingletonObject) || to_var.is_a?(TyGenericObject)
                            to_var.send(:clone_with_substitutions, substitutions)
                          else
                            to_var
                          end
        materialized_function = TyFunction.new(materialized_from, materialized_to, parameters_info, node)
        materialized_function.name = function.name
        materialized_function.block_type = clone_with_substitutions(function.block_type, substitutions) if function.block_type
        materialized_function
      end

      def type_variables
        vars = (from + [to]).map do |arg|
          if arg.is_a?(Polymorphism::TypeVariable)
            arg
          elsif arg.generic?
            arg.type_vars
          end
        end
        vars = vars.flatten.compact

        vars += block_type.type_variables if block_type && block_type.generic?

        # vars.each_with_object({}) do |type_var, acc|
        #   acc[type_var.variable] = type_var
        # end.values
        vars
      end
    end
  end
end
