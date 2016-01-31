module TypedRb
  module Types
    module Polymorphism
      module GenericObject
        def generic?
          true
        end

        def generic_singleton_object
          @generic_singleton_object ||= BasicObject::TypeRegistry.find_generic_type(ruby_type)
        end

        def ancestor_of_super_type?(super_type_klasses, function_klass_type)
          super_type_klasses.detect do |super_type_klass|
            super_type_klass.ruby_type.ancestors.include?(function_klass_type)
          end
        end

        def materialize_super_type_found_function(message, num_args, block,
                                                  super_type,
                                                  super_type_vars)
          super_type_materialization_args = parse_super_type_materialization_args(super_type_vars)
          # we build the concrete type for the arguments based in the subclass bindings and the
          # super type parsed value
          materialized_super_type_in_context = super_type.materialize(super_type_materialization_args).type_vars(recursive: false)
          # Now we check if the parsed type is valid  provided the constraints of the super class
          super_type_generic_object = BasicObject::TypeRegistry.find_generic_type(super_type.ruby_type)
          materialized_super_type = super_type_generic_object.materialize(materialized_super_type_in_context)

          # materialized_super_type.type_vars = super_type.type_vars # ...
          materialized_super_type.as_object_type.find_function_type(message, num_args, block)
        end

        def parse_super_type_materialization_args(super_type_vars)
          super_type_vars.map do |super_type_var|
            parse_super_type_materialization_arg(super_type_var)
          end
        end

        def parse_super_type_materialization_arg(super_type_var)
          return super_type_var if super_type_var.bound
          found_matching_var = type_vars.detect do |var|
            var_name = var.name.split(':').last
            super_type_var.name.index(var_name)
          end
          if found_matching_var
            base_matching_var = found_matching_var.dup
            base_matching_var.name = super_type_var.name
            base_matching_var.variable = super_type_var.variable
            base_matching_var
          else
            fail TypedRb::TypeCheckError,
                 "Error materializing super type annotation for variable #{generic_singleton_object.ruby_type} '#{super_type_var.split(':').last}' not found in base class #{ruby_type}"
          end
        end

        def materialize_found_function(function_type)
          return function_type unless function_type.generic?
          from_args = function_type.from.map { |arg| materialize_found_function_arg(arg) }
          to_arg = materialize_found_function_arg(function_type.to)
          if function_type.block_type
            materialized_block_type = materialize_found_function(function_type.block_type)
          end

          generic_function = (from_args + [to_arg, materialized_block_type]).any? do |arg|
            arg.is_a?(Polymorphism::TypeVariable) ||
                (arg.respond_to?(:generic?) && arg.generic?)
          end

          if generic_function
            materialized_function = TyGenericFunction.new(from_args, to_arg, function_type.parameters_info, node)
            materialized_function.local_typing_context = function_type.local_typing_context
          else
            materialized_function = TyFunction.new(from_args, to_arg, function_type.parameters_info, node)
          end

          materialized_function.with_block_type(materialized_block_type)
        end

        def materialize_found_function_arg(arg)
          if arg.is_a?(Polymorphism::TypeVariable)
            matching_var = generic_type_var_to_applied_type_var(arg)

            # if matching_var && matching_var.wildcard? && matching_var.lower_bound
            #  matching_var.lower_bound
            # elsif matching_var
            # WILDCARD
            if matching_var
              # Type variables and generic methods => function will still be generic
              (matching_var.is_a?(Polymorphism::TypeVariable) && matching_var.bound) || matching_var
            else
              # generic_function = true
              # TyUnboundType.new(matching_var.variable, :lower_bound)
              # fail TypeCheckError, "Cannot find matching type var for #{arg.variable} instantiating #{self}", arg.node
              # method generic var?
              arg
            end
          elsif arg.is_a?(TyGenericSingletonObject)
            arg.materialize_with_type_vars(type_vars, :lower_bound).as_object_type
          else
            arg
          end
        end

        def generic_type_var_to_applied_type_var(type_var)
          i = TypeRegistry.find_generic_type(ruby_type).type_vars.find_index { |generic_type_var| generic_type_var.variable == type_var.variable }
          i && type_vars[i]
        end

        def to_s
          base_string = super
          var_types_strings = @type_vars.map do |var_type|
            if var_type.respond_to?(:bound) && var_type.bound
              # "[#{var_type.variable} <= #{var_type.bound}]"
              "[#{var_type.bound}]"
            else
              "[#{var_type}]"
            end
          end
          "#{base_string}#{var_types_strings.join}"
        end

      end
    end
  end
end

