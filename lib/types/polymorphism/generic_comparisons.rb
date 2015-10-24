module TypedRb
  module Types
    module Polymorphism
      module GenericComparisons
        def compatible?(other_type, relation = :lt)
          if other_type.is_a?(TyDynamic) || other_type.is_a?(TyError)
            true
          elsif other_type.is_a?(TyGenericObject) || other_type.is_a?(TyGenericSingletonObject)
            if check_generic_type_relation(other_type.ruby_type, relation)
              type_vars.each_with_index do |type_var, i|
                other_type_var = other_type.type_vars[i]
                compatible = if incompatible_free_type_vars?(type_var, other_type_var)
                               false
                             elsif compatible_free_type_vars?(type_var, other_type_var)
                               true
                             else
                               check_type_var_inclusion(type_var, other_type_var, relation)
                             end
                return false unless compatible
              end
              true
            else
              false
            end
          else
            false
          end
        end

        def incompatible_free_type_vars?(type_var, other_type_var)
          left_var = type_var.bound || type_var.lower_bound || type_var.upper_bound || type_var
          right_var = other_type_var.bound || other_type_var.lower_bound || other_type_var.upper_bound || other_type_var

          left_var.is_a?(Polymorphism::TypeVariable) &&
            right_var.is_a?(Polymorphism::TypeVariable) &&
            left_var.variable != right_var.variable &&
            (TypingContext.bound_generic_type_var?(left_var) &&
             TypingContext.bound_generic_type_var?(right_var))
        end

        def compatible_free_type_vars?(type_var, other_type_var)
          left_var = type_var.bound || type_var.lower_bound || type_var.upper_bound || type_var
          right_var = other_type_var.bound || other_type_var.lower_bound || other_type_var.upper_bound || other_type_var

          left_var.is_a?(Polymorphism::TypeVariable) &&
            right_var.is_a?(Polymorphism::TypeVariable) &&
            left_var.variable == right_var.variable &&
            (TypingContext.bound_generic_type_var?(left_var) &&
             TypingContext.bound_generic_type_var?(right_var))
        end

        def check_generic_type_relation(other_ruby_type, relation)
          if relation == :gt
            TyObject.new(ruby_type) >= TyObject.new(other_ruby_type)
          else
            TyObject.new(ruby_type) <= TyObject.new(other_ruby_type)
          end
        end

        def check_type_var_inclusion(type_var, other_type_var, relation)
          if (!type_var.wildcard? && !type_var.fully_bound?) ||
             (!other_type_var.wildcard? && !other_type_var.fully_bound?)
            add_type_var_constraint(type_var, other_type_var, relation)
          else
            superset, subset = relation == :lt ? [other_type_var, type_var] : [type_var, other_type_var]

            super_min, super_max, sub_min, sub_max = [superset.lower_bound, superset.upper_bound, subset.lower_bound, subset.upper_bound]. map do |bound|
              if bound.nil? || bound.is_a?(TyUnboundType)
                nil
              else
                bound
              end
            end
            super_max ||= TyObject.new(Object)
            sub_max ||= TyObject.new(Object)

            check_inferior_or_equal_binding(super_min, sub_min) &&
              check_inferior_or_equal_binding(sub_max, super_max)
          end
        end

        # nil < Type_i < Object
        def check_inferior_or_equal_binding(binding_a, binding_b)
          if binding_a.nil? && binding_b.nil?
            true
          elsif binding_a.nil? && !binding_b.nil?
            true
          elsif !binding_a.nil? && binding_b.nil?
            false
          else
            binding_a <= binding_b
          end
        end

        def add_type_var_constraint(type_var, other_type_var, relation)
          if type_var.bound
            type_var, other_type_var = other_type_var, type_var
            relation = relation == :lt ? :gt : :lt
          end
          type_var.add_constraint(relation, other_type_var.bound)
          true
        end
      end
    end
  end
end
