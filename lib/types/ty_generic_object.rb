require_relative 'ty_object'
require_relative 'polymorphism/generic_comparisons'

module TypedRb
  module Types
    class TyGenericObject < TyObject
      include Polymorphism::GenericComparisons

      attr_reader :type_vars

      def initialize(ruby_type, type_vars, node = nil)
        super(ruby_type, node)
        @type_vars = type_vars
      end

      # This object has concrete type parameters
      # The generic Function we retrieve from the registry might be generic
      # If it is generic we apply the bound parameters and we obtain a concrete function type
      def find_function_type(message, num_args, block)
        function_klass_type, function_type = find_function_type_in_hierarchy(:instance, message, num_args, block)
        if function_klass_type != ruby_type && ancestor_of_super_type?(generic_singleton_object.super_type, function_klass_type)
          materialize_super_type_found_function(message, num_args, block)
        else
          TypedRb.log binding, :debug, "Found message '#{message}', generic function: #{function_type}"
          materialized_function = materialize_found_function(function_type)
          TypedRb.log binding, :debug, "Found message '#{message}', materialized generic function: #{materialized_function}"
          [function_klass_type, materialized_function]
        end
      end

      def generic?
        true
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

      def materialize_super_type_found_function(message, num_args, block)
        super_type_object = BasicObject::TypeRegistry.find_generic_type(generic_singleton_object.super_type.ruby_type)
        super_type_vars = generic_singleton_object.super_type.type_vars
        super_type_materialization_args = parse_super_type_materialization_args(super_type_vars)
        materialized_super_type = super_type_object.materialize(super_type_materialization_args)
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

      def ancestor_of_super_type?(super_type_klass, function_klass_type)
        return false if super_type_klass.nil?
        super_type_klass.ruby_type.ancestors.include?(function_klass_type)
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
            matching_var.bound || matching_var
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

      def to_s
        base_string = super
        var_types_strings = @type_vars.map do |var_type|
          if var_type.bound
            # "[#{var_type.variable} <= #{var_type.bound}]"
            "[#{var_type.bound}]"
          else
            "[#{var_type}]"
          end
        end
        "#{base_string}#{var_types_strings.join}"
      end

      def clone_with_substitutions(substitutions)
        materialized_type_vars = type_vars.map do |type_var|
          if type_var.is_a?(Polymorphism::TypeVariable)
            substitutions[type_var.variable] || type_var.clone
          elsif type_var.is_a?(TyGenericSingletonObject) || type_var.is_a?(TyGenericObject)
            type_var.clone_with_substitutions(substitutions)
          else
            type_var
          end
        end
        self.class.new(ruby_type, materialized_type_vars, node)
      end

      def apply_bindings(bindings_map)
        type_vars.each_with_index do |var, i|
          if var.is_a?(Polymorphism::TypeVariable)
            var.apply_bindings(bindings_map)
            type_vars[i] = var.bound if var.bound && var.bound.is_a?(Polymorphism::TypeVariable)
          elsif var.is_a?(TyGenericSingletonObject) || var.is_a?(TyGenericObject)
            var.apply_bindings(bindings_map)
          end
        end
        self
      end

      def generic_singleton_object
        @generic_singleton_object ||= BasicObject::TypeRegistry.find_generic_type(ruby_type)
      end

      def generic_type_var_to_applied_type_var(type_var)
        i = TypeRegistry.find_generic_type(ruby_type).type_vars.find_index { |generic_type_var| generic_type_var.variable == type_var.variable }
        i && type_vars[i]
      end
    end
  end
end
