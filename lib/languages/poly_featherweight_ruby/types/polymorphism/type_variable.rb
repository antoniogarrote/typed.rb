module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Types
        module Polymorphism
          class TypeVariable
            attr_reader :bound, :variable, :upper_bound

            def initialize(var_name, options = {})
              gen_name = options[:gen_name].nil? ? true : options[:gen_name]
              @upper_bound = options[:upper_bound]
              @variable = gen_name ? Model::GenSym.next("TV_#{var_name}") : var_name
              @bound = nil
            end

            def add_constraint(relation, type)
              TypingContext.add_constraint(variable, relation, type)
            end

            def add_message_constraint(message, args)
              return_type = TypingContext.type_variable_for_message(variable, message)
              # add constraint for this
              add_constraint(:send, args: args, return: return_type, message: message)
              # return return type
              return_type
            end

            def compatible?(type, relation = :lt)
              if @bound
                @bound.compatible?(type,relation)
              else
                add_constraint(relation, type)
              end
              true
            end

            def constraints(register = TypingContext)
              register.constraints_for(variable).map { |(t, c)| [self, t, c] }
            end

            def check_type(_context)
              self
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
