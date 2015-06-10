module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Types
        module Polymorphism
          class TypeVariable
            attr_reader :bound
            def initialize(var_name)
              @constraints = []
              @variable = TypedRb::Languages::PolyFeatherweightRuby::Model::GenSym.next("TV_#{var_name}")
              @bound = nil
            end

            def add_constraint(relation, type)
              @constraints << [relation, type]
            end

            def compatible?(type, relation = :lt)
              if @bound
                @bound.compatible?(type,relation)
              else
                add_constraint(relation, type)
              end
              self
            end

            def constraints
              @constraints.map { |(t,c)| [self, t, c] }
            end

            def bind(type)
              @bound = type
            end

            def unbind
              @bound = nil
            end

            def to_s
              "#{@variable}:#{@bound || '?'}"
            end
          end

          class Unification
            attr_reader :constraints, :bindings
            def initialize(constraints)
              @constraints = constraints.sort do |(_la, ta, _ra), (_lb, tb, _rb)|
                if ta == :gt && tb == :lt
                  -1
                elsif ta == :lt && tb == :gt
                  1
                else
                  0
                end
              end
              @variables = constraints.map { |(l, _t, _r)| l }.uniq
            end

            def run(bind_variables = true)
              @bindings = {}
              unify(@constraints)
              if bind_variables
                @variables.each do |variable|
                  @bindings.each do |(key, value)|
                    variable.bind(value) if key[variable]
                  end
                end
              end
              self
            end

            protected

            def unify(constraints)
              unless constraints.empty?
                (l, t, r), rest = constraints.first, constraints.drop(1)
                if l == r
                  unify(rest)
                else
                  bind(l, t, r)
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

            def bind(l, t, r)
              if r.is_a?(TypeVariable)
                group_l, value_l = find_bound_var(l)
                group_r, value_r = find_bound_var(r)
                group_union = group_l.merge(group_r)
                @binddings.delete(group_l)
                @binddings.delete(group_r)
                # this should throw an exception if types no compatible
                @bindings[group_union] = compatible_type?(value_l, t, value_r)
              else
                group_l, value_l = find_bound_var(l)
                # this should throw an exception if types no compatible
                @bindings[group_l] = compatible_type?(value_l, t, r)
              end
            end

            def find_bound_var(var)
              key = @bindings.keys.detect { |key| key.include?(var) } || {var => true}
              [key, @bindings[key]]
            end

            def compatible_type?(value_l, t, value_r)
              if value_l.nil? || value_r.nil?
                value_l || value_r
              else
                case t
                when :gt # assignations, e.g v = Int, v = Num => v : Num
                    value_l > value_r ? value_l : value_r
                when :lt # applications, return e.g. return Int, return Num => => v : Int
                    value_l < value_r ? value_l : fail(RuntimeError.new("Error checking type #{value_l} > #{value_r}"))
                else
                  fail StandardError, "Unknown type constraint #{t}"
                end
              end
            end

            def replace(rest, l, r, acc = [])
              if rest.empty?
                acc
              else
                a,b = rest.first
                replace(rest.drop(1), l, r, acc << [a == l ? r : a, b == l ? r : b])
              end
            end
          end
        end
      end
    end
  end
end
