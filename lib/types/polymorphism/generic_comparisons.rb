module TypedRb
  module Types
    module Polymorphism
      module GenericComparisons
        def compatible?(other_type, relation = :lt)
          if other_type.is_a?(TyDynamic)
            true
          elsif (other_type.is_a?(TyGenericObject) || other_type.is_a?(TyGenericSingletonObject))
            if check_generic_type_relation(other_type.ruby_type, relation)
              acc = true
              type_vars.each_with_index do |type_var, i|
                other_type_var = other_type.type_vars[i]
                acc = acc && check_type_var_inclusion(type_var, other_type_var, relation)
                return acc if acc == false
              end
              acc
            else
              false
            end
          else
            false
          end
        end

        def check_generic_type_relation(other_ruby_type, relation)
          if relation == :gt
            TyObject.new(ruby_type) >= TyObject.new(other_ruby_type)
          else
            TyObject.new(ruby_type) <= TyObject.new(other_ruby_type)
          end
        end

        def check_type_var_inclusion(type_var, other_type_var, relation)
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
      end
    end
  end
end
