require_relative 'ty_object'
require_relative 'polymorphism/generic_comparisons'
require_relative 'polymorphism/generic_variables'
require_relative 'polymorphism/generic_object'

module TypedRb
  module Types
    class TyGenericObject < TyObject
      include Polymorphism::GenericObject
      include Polymorphism::GenericComparisons
      include Polymorphism::GenericVariables

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
          target_class = ancestor_of_super_type?(generic_singleton_object.super_type, function_klass_type)
          TypedRb.log binding, :debug, "Found message '#{message}', generic function: #{function_type}, explicit super type #{target_class}"
          target_type_vars = target_class.type_vars
          materialize_super_type_found_function(message, num_args, block, target_class, target_type_vars)
        elsif function_klass_type != ruby_type && BasicObject::TypeRegistry.find_generic_type(function_klass_type)
          TypedRb.log binding, :debug, "Found message '#{message}', generic function: #{function_type}, implict super type #{function_klass_type}"
          target_class = BasicObject::TypeRegistry.find_generic_type(function_klass_type)
          materialize_super_type_found_function(message, num_args, block, target_class, type_vars)
        else
          TypedRb.log binding, :debug, "Found message '#{message}', generic function: #{function_type}"
          materialized_function = materialize_found_function(function_type)
          TypedRb.log binding, :debug, "Found message '#{message}', materialized generic function: #{materialized_function}"
          [function_klass_type, materialized_function]
        end
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

      def clone_with_substitutions(substitutions)
        materialized_type_vars = type_vars(recursive: false).map do |type_var|
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

    end
  end
end
