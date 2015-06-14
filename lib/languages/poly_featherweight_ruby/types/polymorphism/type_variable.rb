module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Types
        module Polymorphism
          class TypeVariable
            attr_reader :bound, :variable
            def initialize(var_name)
              @constraints = []
              @variable = Model::GenSym.next("TV_#{var_name}")
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
        end
      end
    end
  end
end
