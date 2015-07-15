module TypedRb
  module Types
    # Polymorphic additions to Featherweight Ruby
    module Polymorphism
      class TypeVariableRegister
        attr_accessor :parent, :constraints, :children, :type_variables_register, :kind

        def initialize(parent=nil, kind)
          @kind = kind
          @parent = parent
          if @parent
            @parent.children << self
            @parent.children.uniq!
          end
          @children = []
          @constraints = {}
          @type_variables_register = {}
        end

        def type_variable_for(type, variable, hierarchy)
          ensure_string(variable)
          upper_level = upper_class_register
          key = hierarchy.map do |ruby_type|
            [type, ruby_type, variable]
          end.detect do |constructed_key|
            upper_level.type_variables_register[constructed_key]
          end
          if key.nil?
            new_var_name = "#{hierarchy.first}:#{variable}"
            type_var = TypeVariable.new(new_var_name)
            type_variables_register[[type, hierarchy.first, variable]] = type_var
            type_var
          else
            upper_level.type_variables_register[key]
          end
        end

        def type_variable_for_global(variable)
          ensure_string(variable)
          upper_level = top_level_register
          key = [:global, nil, variable]
          type_var = upper_level.type_variables_register[key]
          if type_var.nil?
            type_var = TypeVariable.new(variable, :gen_name => false)
            upper_level.type_variables_register[key] = type_var
          end
          type_var
        end

        def type_variable_for_message(variable, message)
          ensure_string(variable)
          key = [:return, message, variable]
          type_var = recursive_constraint_search(key)
          if type_var.nil?
            new_var_name = "#{variable}:#{message}"
            type_var = TypeVariable.new(new_var_name)
            type_variables_register[key] = type_var
          end
          type_var
        end

        def type_variable_for_abstraction(abs_kind, variable, context)
          if variable.nil?
            variable = Model::GenSym.next("#{abs_kind}_ret}")
          end
          ensure_string(variable)
          key = [abs_kind.to_sym, context.context_name, variable]
          type_var = recursive_constraint_search(key)
          if type_var.nil?
            # don't gnerate a random fresh name for the var, use the one we're
            # providing
            new_var_name = "TV_#{context.context_name}:#{abs_kind}:#{variable}"
            type_var = TypeVariable.new(new_var_name, gen_name: false)
            type_variables_register[key] = type_var
          end
          type_var
        end

        def type_variable_for_generic_type(type_var)
          key = [:generic,  nil, type_var.variable]
          type_var_in_registry = type_variables_register[key]
          if type_var_in_registry
            type_var_in_registry
          else
            type_var_in_registry = Polymorphism::TypeVariable.new(type_var.variable,
                                                                  :upper_bound => type_var.upper_bound,
                                                                  :gen_name    => false)
            type_variables_register[key] = type_var_in_registry
            type_var_in_registry
          end
        end



        def constraints_for(variable)
          found = constraints[variable]
          children_found = children.map{ |child_context|  child_context.constraints_for(variable) }.reduce(&:+)
          (found || []) + (children_found || [])
        end

        # @type_variables_register
        # code_name => type_var
        # @constraints
        # type_var => constraint
        def all_constraints
          self_variables_constraints = @type_variables_register.values.reduce([]) do |constraints_acc, type_var|
            constraints_acc + type_var.constraints(self)
          end
          self_variables_constraints + (children.map { |register| register.all_constraints }.reduce(&:+) || [])
        end

        def all_variables
          @type_variables_register.values
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
          register.type_variables_register = type_variables_register.each_with_object({}) do |((k, i, v), var), acc|
            acc[[k, i, v]] = type_variable_mapping[var.variable] || var
          end
          register.constraints = rename_constraints(constraints, type_variable_mapping)
          register.children = children.map { |child_register| child_register.apply_type(register, type_variable_mapping) }
          register
        end

        def rename_constraints(constraints, type_variable_mapping)
          constraints.each_with_object({}) do |(variable_name, values), acc|
            new_variable_name = type_variable_mapping[variable_name] ? type_variable_mapping[variable_name].variable : variable_name
            new_values = values.map do |(rel, type)|
              if(rel == :send)
                old_return_type = type[:return]
                new_return_type = if old_return_type.is_a?(TypeVariable)
                                    type_variable_mapping[old_return_type.variable] ? type_variable_mapping[old_return_type.variable] : old_return_type
                                  else
                                    old_return_type
                                  end
                new_args = type[:args].map do |arg|
                  if arg.is_a?(TypeVariable)
                    type_variable_mapping[arg.variable] ? type_variable_mapping[arg.variable] : arg
                  else
                    arg
                  end
                end
                [:send, {args: new_args, return: new_return_type, message: type[:message]}]
              else
                if type.is_a?(TypeVariable) && type_variable_mapping[type.variable]
                  [rel, type_variable_mapping[type.variable]]
                else
                  [rel, type]
                end
              end
            end
            acc[new_variable_name] = new_values
          end
        end

        def local_var_types
          @type_variables_register.map do |(key,value)|
            type = key.first
            if type != :instance_variable && type != :class_variable
              value
            end
          end.compact
        end

        def generic_type_local_var_types
          @type_variables_register.map do |(key,value)|
            type = key.first
            if type == :instance_variable || type == :class_variable || type == :generic
              value
            end
          end.compact
        end

        protected

        def recursive_constraint_search(key)
          current = self
          found = nil
          while found.nil? && !current.nil?
            found = current.type_variables_register[key]
            current = current.parent unless current.nil?
          end
          found
        end

        # We find the first registry that has been created
        # in the context of a generic class or the top level
        # registry if none is found.
        # The registry can be the current one.
        def upper_class_register
          current = self
          while current.kind != :top_level && current.kind != :class
            current = current.parent
          end
          current
        end

        def top_level_register
          current = self
          while current.kind != :top_level
            current = current.parent
          end
          current
        end

        def ensure_string(variable)
          variable = variable.to_s if variable.is_a?(Symbol)
          fail StandardError, "Variable name must be a String for register" unless variable.is_a?(String)
        end
      end
    end
  end
end
