module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Types
        module Polymorphism
          class TypeVariable
            def initialize(var_name)
              @constraints = []
              @variable = TypedRb::Languages::PolyFeatherweightRuby::Model::GenSym.next("TV_#{var_name}")
            end

            def add_constraint(type)
              @constraints << type
            end

            def compatible?(type)
              add_constraint(type)
              self
            end

            def constraints
              @constraints.map { |c| [self, c] }
            end

            def to_s
              @variable
            end
          end

          class Unification
            attr_reader :constraints
            def initialize(constraints)
              @constraints = constraints
            end

            def run
              @bindings = {}
              unify(@constraints)
            end

            protected

            def unify(constraints)
              unless constraints.empty?
                (l,r), rest = constraints.first, constraints.drop(1)
                if l == r
                  unify(rest)
                  else
                    bind(l,r)
                    if l.is_a?(TypeVariable) && r.is_a?(TypeVariable) && free?(r)
                      rest = replace(rest, l, r)
                    end
                    unify(rest)
                end
              end
            end

            def free?(var)
              @bindings[var].nil?
            end

            def bind(l,r)
              if r.is_a?(TypeVariable)
                group_l, value_l = find_bound_var(l)
                group_r, value_r = find_bound_var(r)
                group_union = group_l.merge(group_r)
                @binddings.delete(group_l)
                @binddings.delete(group_r)
                @bindings[group_union] = compatible_type?(value_l, value_r)
              else
                group_l, value_l = find_bound(var(l))
                @bindings[group_l] = compatible_type?(value_l, r)
              end
            end

            def find_bound_var(var)
              key = @bindings.keys.detect { |key| key.include?(var) } || {}
              [key, @bindings[key]]
            end

            def compatible_type?(value_l, value_r)
              if value_l.nil? || value_r.nil?
                value_l || value_r
              else

              end
            end
          end
        end
      end
    end
  end
end
