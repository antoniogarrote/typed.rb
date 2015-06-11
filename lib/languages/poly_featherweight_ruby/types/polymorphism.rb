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
              @constraints = constraints
              @gt_constraints = @constraints.select { |(_, t, _r)| t == :gt }
              @lt_constraints = @constraints.select { |(_, t, _r)| t == :lt }
              @variables = constraints.map { |(l, _t, _r)| l }.uniq
            end

            def run(bind_variables = true)
              @bindings = {}
              @graph = {}
              unify(@gt_constraints)
              @lt_constraints = unify_variables_graph(@lt_constraints)
              unify(@lt_constraints)
              if bind_variables
                @variables.each do |variable|
                  @bindings.each do |(key, value)|
                    variable.bind(value) if key == variable || key[variable]
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
                  if l.is_a?(TypeVariable) && r.is_a?(TypeVariable)
                    # this is only going to happen in the first invocation to unify
                    link(l, r)
                  else
                    # in the first invocation to unify, l must always be a TypeVar, t :gt and r a type variable or a type,
                    # in the second invocation to unify, l must always be a group, t :lt and r a type variable,
                    bind(l, t, r)
                  end
                  unify(rest)
                end
              end
            end

            def unify_variables_graph(constraints)
              @graph.each do |(group, links)|

                join_type = (group.keys + links.keys).map{ |var| @bindings[var] }.uniq.reduce do |ta, tb|
                  compatible_type? ta, :gt, tb
                end
                group.keys.each do |l|
                  constraints = replace(constraints, l, group)
                  @bindings.delete(l)
                end
                @bindings[group] = join_type
              end
              @bindings.keys.select{ |k| !k.is_a?(Hash) }.each do |key|
                @bindings[{key => true}] = @bindings.delete(key)
              end
              constraints
            end

            def bind(l, t, r)
              value_l = (@bindings.detect{ |(key,_value)| key.is_a?(Hash) ? key.include?(l) : key == l } || []).last
              # this will throw an exception if types no compatible
              @bindings[l] = compatible_type?(value_l, t, r)
            end

            def compatible_type?(value_l, t, value_r)
              if value_l.nil? || value_r.nil?
                value_l || value_r
              else
                case t
                when :gt # assignations, e.g v = Int, v = Num => v : Num
                  begin
                    value_l > value_r ? value_l : value_r
                  rescue TypedRb::Languages::PolyFeatherweightRuby::Types::UncomparableTypes
                    value_l.join(value_r)
                  end
                when :lt # applications, return e.g. return Int, return Num => => v : Int
                    value_l <= value_r ? value_l : fail(RuntimeError.new("Error checking type #{value_l} > #{value_r}"))
                else
                  fail StandardError, "Unknown type constraint #{t}"
                end
              end
            end

            def link(l,r)
              group_l, links_l = @graph.detect{ |(group,_links)| group[l] } || [{l => true}, {r => true}]
              group_r, links_r = @graph.detect{ |(group,_links)| group[r] } || [{r => true}, {}]

              if links_r[l] && links_l[r]
                # merge groups, variables are the same type
                group_common = group_l.merge(group_r)
                links_common = links_l.merge(links_r)
                @graph.delete(group_l)
                @graph.delete(group_r)
                @graph[group_common] = links_common
              else
                # add the arc => l < r
                links_l[r] = true
                @graph[group_l] = links_l
              end
            end

            def replace(rest, l, r, acc = [])
              if rest.empty?
                acc
              else
                a, t, b = rest.first
                replace(rest.drop(1), l, r, acc << [a == l ? r : a, t, b == l ? r : b])
              end
            end
          end
        end
      end
    end
  end
end
