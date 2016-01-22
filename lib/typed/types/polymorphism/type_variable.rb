module TypedRb
  module Types
    module Polymorphism
      class TypeVariable
        attr_accessor :bound, :variable, :upper_bound, :lower_bound, :name, :node

        def initialize(var_name, options = {})
          gen_name = options[:gen_name].nil? ? true : options[:gen_name]
          @upper_bound = options[:upper_bound]
          @lower_bound = options[:lower_bound]
          @node = options[:node]
          @wildcard = var_name.to_s.end_with?('?')
          var_name.sub!(/:?\?/, '') if @wildcard
          @name = var_name
          @variable = gen_name ? Model::GenSym.next("TV_#{var_name}") : var_name
          @bound = options[:bound]
        end

        def stack_jump?
          false
        end

        def either?
          false
        end

        def add_constraint(relation, type)
          if type.is_a?(TypeVariable) && type.bound
            TypingContext.add_constraint(variable, relation, type.bound)
          else
            TypingContext.add_constraint(variable, relation, type)
          end
        end

        def add_message_constraint(message, args)
          return_type = TypingContext.type_variable_for_message(variable, message)
          return_type.node = node
          # add constraint for this
          add_constraint(:send, args: args, return: return_type, message: message)
          # return return type
          return_type
        end

        def compatible?(type, relation = :lt)
          if @bound
            @bound.compatible?(type, relation)
          else
            add_constraint(relation, type)
            true
          end
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

        def fully_bound?
          !upper_bound.nil? && !lower_bound.nil?
        end

        def wildcard?
          @wildcard
        end

        def to_wildcard!
          @wildcard = true
        end

        def apply_bindings(bindings_map)
          bound_var = bindings_map[variable]
          if bound_var && bound.nil?
            self.bound = bound_var.bound
            self.upper_bound = bound_var.upper_bound
            self.lower_bound = bound_var.lower_bound
            self.to_wildcard! if bound_var.wildcard?
          elsif bound && (bound.is_a?(TyGenericSingletonObject) || bound.is_a?(TyGenericObject))
             bound.apply_bindings(bindings_map)
          end
          self
        end

        def unbind
          @bound = nil
        end

        def clone
          var = TypeVariable.new(variable,
                                 node: node,
                                 gen_name: false,
                                 upper_bound: upper_bound,
                                 lower_bound: lower_bound,
                                 bound: bound)
          var.to_wildcard! if wildcard?
          var
        end

        def to_s
          wildcard_part = wildcard? ? '*' : ''
          bound_part = if @bound
                         @bound
                       else
                         "[#{lower_bound || '?'},#{upper_bound || '?'}]"
                       end
          "#{@variable}#{wildcard_part}::#{bound_part}"
        end

        def bound_to_generic?
          bound && bound.respond_to?(:generic?) && bound.generic?
        end
      end
    end
  end
end
