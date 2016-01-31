module TypedRb
  module Types
    module SingletonObject
      def apply_type_arguments(fresh_vars_generic_type, actual_arguments)
        fresh_vars_generic_type.type_vars.each_with_index do |type_var, i|
          if type_var.bound.is_a?(TyGenericSingletonObject)
            type_var.bind(apply_type_arguments_recursively(type_var.bound, actual_arguments))
          else
            apply_type_argument(actual_arguments[i], type_var)
          end
        end
      end

      def clone_with_substitutions(substitutions)
        materialized_type_vars = type_vars(recursive: false).map do |type_var|
          if type_var.is_a?(Polymorphism::TypeVariable) && type_var.bound_to_generic?
            new_type_var = Polymorphism::TypeVariable.new(type_var.variable, node: type_var.node, gen_name: false)
            new_type_var.to_wildcard! if type_var.wildcard?
            bound = type_var.bound.clone_with_substitutions(substitutions)
            new_type_var.bind(bound)
            new_type_var.upper_bound = bound if type_var.upper_bound
            new_type_var.lower_bound = bound if type_var.lower_bound
            new_type_var
          elsif type_var.is_a?(Polymorphism::TypeVariable)
            substitutions[type_var.variable] || type_var.clone
          elsif type_var.is_a?(TyGenericSingletonObject) || type_var.is_a?(TyGenericObject)
            type_var.clone_with_substitutions(substitutions)
          else
            type_var
          end
        end
        self.class.new(ruby_type, materialized_type_vars, node)
      end

      def apply_type_argument(argument, type_var)
        if argument.is_a?(Polymorphism::TypeVariable)
          if argument.wildcard?
            # Wild card type
            # If the type is T =:= E < Type1 or E > Type1 only that constraint should be added
            { :lt => :upper_bound, :gt => :lower_bound }.each do |relation, bound|
              if argument.send(bound)
                value = if argument.send(bound).is_a?(TyGenericSingletonObject)
                          argument.send(bound).clone # .self_materialize
                        else
                          argument.send(bound)
                        end
                type_var.compatible?(value, relation)
              end
            end
            type_var.to_wildcard! # WILD CARD
          elsif argument.bound # var type with a particular value
            argument = argument.bound
            if argument.is_a?(TyGenericSingletonObject)
              argument = argument.clone # .self_materialize
            end
            # This is only for matches T =:= Type1 -> T < Type1, T > Type1
            fail Types::UncomparableTypes.new(type_var, argument) unless type_var.compatible?(argument, :lt)
            fail Types::UncomparableTypes.new(type_var, argument) unless type_var.compatible?(argument, :gt)
          else
            # Type variable
            type_var.bound = argument
            type_var.lower_bound = argument
            type_var.upper_bound = argument
          end
        else
          if argument.is_a?(TyGenericSingletonObject)
            argument = argument.clone # .self_materialize
          end
          # This is only for matches T =:= Type1 -> T < Type1, T > Type1
          fail Types::UncomparableTypes.new(type_var, argument) unless type_var.compatible?(argument, :lt)
          fail Types::UncomparableTypes.new(type_var, argument) unless type_var.compatible?(argument, :gt)
        end
      end

      def apply_type_arguments_recursively(generic_type_bound, actual_arguments)
        arg_names = actual_arguments_hash(actual_arguments)
        recursive_actual_arguments = generic_type_bound.type_vars.map do |type_var|
          arg_names[type_var.variable] || fail("Unbound type variable #{type_var.variable} for recursive generic type #{generic_type_bound}")
        end
        generic_type_bound.materialize(recursive_actual_arguments)
      end

      def actual_arguments_hash(actual_arguments)
        acc = {}
        type_vars.each_with_index do |type_var, i|
          acc[type_var.variable] = actual_arguments[i]
        end
        acc
      end
    end
  end
end