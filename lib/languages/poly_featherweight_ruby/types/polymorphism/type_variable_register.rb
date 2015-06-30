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
              class_for_type_var = hierarchy.detect do |ruby_type|
                type_variables_register[[type, ruby_type, variable]]
              end
              if class_for_type_var.nil?
                new_var_name = "#{hierarchy.first}:#{variable}"
                type_var = TypeVariable.new(new_var_name)
                type_variables_register[[type, hierarchy.first, variable]] = type_var
                type_var
              else
                type_variables_register[[type, class_for_type_var, variable]]
              end
            end

            def type_variable_for_message(variable, message)
              ensure_string(variable)
              key = [:return, message, variable]
              type_var = type_variables_register[key]
              if type_var.nil?
                new_var_name = "#{variable}:#{message}"
                type_var = TypeVariable.new(new_var_name)
                type_variables_register[key] = type_var
              end
              type_var
            end

            def type_variable_for_abstraction(abs_kind, variable, context)
              ensure_string(variable)
              key = [abs_kind.to_sym, context.context_name, variable]
              type_var = type_variables_register[key]
              if type_var.nil?
                # don't gnerate a random fresh name for the var, use the one we're
                # providing
                new_var_name = "TV_#{context.context_name}:#{abs_kind}:#{variable}"
                type_var = TypeVariable.new(new_var_name, gen_name: false)
                type_variables_register[key] = type_var
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
                type, info, variable = constraint
                new_variable = type_variable_mapping[variable] || variable
                [type, info, new_variable]
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
