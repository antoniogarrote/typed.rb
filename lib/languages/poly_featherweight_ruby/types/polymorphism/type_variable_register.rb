module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Types
        # Polymorphic additions to Featherweight Ruby
        module Polymorphism
          class TypeVariableRegister

            attr_accessor :parent, :constraints, :children

            def initialize(parent=nil)
              @parent = parent
              @parent.children << self if @parent
              @children = []
              @constraints = {}
            end

            def type_variable_for(type, variable, hierarchy)
              ensure_string(variable)
              type_var = hierarchy.detect do |ruby_type|
                type_variables_register[[type, ruby_type, variable]]
              end

              type_var = if type_var.nil?
                           new_var_name = "#{hierarchy.first}:#{variable}"
                           TypeVariable.new(new_var_name)
                         else
                           type_variables_register[[type, type_var, variable]]
                         end
              type_variables_register[[type, hierarchy.first, variable]] = type_var
              type_var
            end

            def type_variable_for_message(variable, message)
              ensure_string(variable)
              new_var_name = "#{variable}:#{message}"
              type_var = type_variables_register[[:return, new_var_name]]
              if type_var.nil?
                type_var = TypeVariable.new(new_var_name)
                type_variables_register[[:return, new_var_name]] = type_var
              end
              type_var
            end

            def type_variable_for_abstraction(abs_kind, variable, context)
              ensure_string(variable)
              new_var_name = "TV_#{context.context_name}:#{abs_kind}:#{variable}"
              new_var_name = Model::GenSym.next(new_var_name)
              type_var = type_variables_register[[abs_kind.to_sym, new_var_name]]
              if type_var.nil?
                # don't gnerate a random fresh name for the var, use the one we're
                # providing
                type_var = TypeVariable.new(new_var_name, gen_name: false)
                type_variables_register[[abs_kind.to_sym, new_var_name]] = type_var
              end
              type_var
            end

            def type_variables_register
              @type_variable_register ||= {}
            end

            def all_constraints
              @type_variable_register.values.reduce([]) do |constraints, type_var|
                constraints + type_var.constraints
              end
            end

            def all_variables
              @type_variable_register.values
            end

            def clear
              @parent = nil
              @constraints.clear
              type_variables_register.clear
            end

            def add_constraint(variable_name, relation_type, type)
              var_constraints = @constraints[variable_name] || []
              var_constraints << [relation_type, type]
              @constraints[variable_name] = var_constraints
            end

            def apply_type(parent, type_variable_mapping)
              register = TypeVariableRegister.new(parent)
              register.constraints = rename_constraints(constraints, type_variable_mapping)
              register.children = children.map { |child_register| child_register.apply_type(register, type_variable_mapping) }
              register
            end

            def rename_constraints(constraints, type_variable_mapping)
              constraints.map do |constraint|
                if constraint.size == 2
                  type, variable = constraint
                  new_variable = type_variable_mapping[variable] || variable
                  [type, new_variable]
                elsif constraint.size == 3
                  type, hierachy, variable = constraint
                  new_variable = type_variable_mapping[variable] || variable
                  [type, hierachy, new_variable]
                else
                  fail StandardError, "Unknown type of constraint #{constraint.to_s}"
                end
              end
            end

            protected

            def ensure_string(variable)
              variable = variable.to_s if variable.is_a?(Symbol)
              fail StandardError, "Variable name must be a String for register" unless variable.is_a?(String)
            end
          end
        end
      end
    end
  end
end
