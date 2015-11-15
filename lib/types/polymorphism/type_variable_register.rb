module TypedRb
  module Types
    # Polymorphic additions to Featherweight Ruby
    module Polymorphism
      class TypeVariableRegister
        attr_accessor :parent, :constraints, :children, :type_variables_register, :kind

        class << self
          def local_var_counter
            @local_var_counter ||= 0
            @local_var_counter += 1
          end
        end

        def initialize(parent = nil, kind)
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

        def unlink
          return if @parent.nil?
          @parent.children.delete(self)
        end

        def type_variable_for(type, variable, hierarchy)
          ensure_string(variable)
          upper_level = upper_class_register # we need to get a class register
          key = hierarchy.map do |ruby_type|
            [type, ruby_type, variable]
          end.detect do |constructed_key|
            upper_level.type_variables_register[constructed_key]
          end
          if key.nil?
            type_var = upper_level.type_variables_register[[type, hierarchy.first, variable]]
            if type_var.nil?
              new_var_name = "#{hierarchy.first}:#{variable}"
              type_var = if variable == :module_self
                           ExistentialTypeVariable.new(new_var_name, :gen_name => false)
                         else
                           TypeVariable.new(new_var_name, :gen_name => false)
                         end
              upper_level.type_variables_register[[type, hierarchy.first, variable]] = type_var
              type_var
            else
              type_var
            end
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
          variable = Model::GenSym.next("#{abs_kind}_ret}") if variable.nil?
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

        def type_variable_for_generic_type(type_var, method = false)
          key = [:generic,  method, type_var.variable]
          type_var_in_registry = type_variables_register[key]
          if type_var_in_registry
            type_var_in_registry
          else
            type_var_in_registry = type_var.clone
            type_variables_register[key] = type_var_in_registry
            type_var_in_registry
          end
        end

        def local_type_variable
          var_name = "local_var_#{TypeVariableRegister.local_var_counter}"
          key = [:local,  nil, var_name]
          type_var_in_registry = TypeVariable.new(var_name)
          type_variables_register[key] = type_var_in_registry
          type_var_in_registry
        end

        def bound_generic_type_var?(type_variable)
          found = type_variables_register[[:generic, false, type_variable.name]] ||
                  type_variables_register[[:generic, true, type_variable.name]]

          if found
            kind == :method || kind == :class
          elsif !parent.nil?
            parent.bound_generic_type_var?(type_variable)
          else
            false
          end
        end

        def constraints_for(variable)
          found = constraints[variable]
          children_found = children.map { |child_context|  child_context.constraints_for(variable) }.reduce(&:+)
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
          self_variables_constraints + (children.reject{ |r| r.kind == :module }.map(&:all_constraints).reduce(&:+) || [])
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
          TypedRb.log(binding, :debug, "Adding constraint #{variable_name} #{relation_type} #{type}")
          if type_variables_register.values.detect { |variable| variable.variable == variable_name }
            var_constraints = @constraints[variable_name] || []
            var_constraints << [relation_type, type]
            @constraints[variable_name] = var_constraints
          elsif parent
            parent.add_constraint(variable_name, relation_type, type)
          else
            fail StandardError, "Cannot find variable #{variable_name} to add a constraint"
          end
        end

        def include?(variable)
          found = @type_variables_register.values.detect do |var|
            var.variable == variable
          end
          return true if found
          return false if parent.nil?
          parent.include?(variable)
        end

        def print_constraints
          constraints.each do |(variable_name, constraints)|
            constraints.each do |(rel, val)|
              if rel == :send
                puts "#{variable_name} #{rel} #{val[:message]}#{val[:args].map(&:to_s).join(',')}"
              else
                puts "#{variable_name} #{rel} #{val}"
              end
            end
          end
        end

        def clone(scope)
          vars = (scope == :method) ? method_var_types : class_var_types
          substitutions = vars.each_with_object({}) do |var_type, acc|
            acc[var_type.variable] = var_type.clone
          end
          [apply_type(parent, substitutions), substitutions]
        end

        protected

        def method_var_types
          @type_variables_register.map do |(key, value)|
            type = key.first
            value if type != :instance_variable && type != :class_variable
          end.compact
        end

        def class_var_types
          @type_variables_register.map do |(key, value)|
            type = key.first
            if type == :instance_variable || type == :class_variable || type == :generic
              value
            end
          end.compact
        end

        def apply_type(parent, type_variable_mapping)
          register = TypeVariableRegister.new(parent, kind)
          apply_type_to_register(register, type_variable_mapping)
        end

        def apply_type_to_register(register, type_variable_mapping)
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
              if (rel == :send)
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
                [:send, { args: new_args, return: new_return_type, message: type[:message] }]
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
          while current.kind != :top_level && current.kind != :class && current.kind != :module
            current = current.parent
          end
          current
        end

        def top_level_register
          current = self
          current = current.parent while current.kind != :top_level
          current
        end

        def ensure_string(variable)
          variable = variable.to_s if variable.is_a?(Symbol)
          fail StandardError, 'Variable name must be a String for register' unless variable.is_a?(String)
        end
      end
    end
  end
end
