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
      def find_function_type(message)
        function_klass_type, function_type = find_function_type_in_hierarchy(:instance, message)
        TypedRb.log binding, :debug, "Found message '#{message}', generic function: #{function_type}"
        materialised_function = materialise_found_function(function_type)
        TypedRb.log binding, :debug, "Found message '#{message}', materialised generic function: #{materialised_function}"
        [function_klass_type, materialised_function]
      end

      def generic?
        true
      end

      def materialise_found_function(function_type)
        from_args = function_type.from.map { |arg| materialise_found_function_arg(arg) }
        to_arg = materialise_found_function_arg(function_type.to)
        if function_type.block_type
          materialised_block_type = materialise_found_function(function_type.block_type)
        end

        generic_function = (from_args + [to_arg, materialised_block_type]).any? do |arg|
          arg.is_a?(Polymorphism::TypeVariable) ||
            (arg.respond_to?(:generic?) && arg.generic?)
        end

        if generic_function
          materialised_function = TyGenericFunction.new(from_args, to_arg, function_type.parameters_info, node)
          materialised_function.local_typing_context = function_type.local_typing_context
        else
          materialised_function = TyFunction.new(from_args, to_arg, function_type.parameters_info, node)
        end

        materialised_function.with_block_type(materialised_block_type)
      end

      def materialise_found_function_arg(arg)
        if arg.is_a?(Polymorphism::TypeVariable)
          matching_var = type_vars.detect do |type_var|
            type_var.variable == arg.variable ||
              (type_var.bound && type_var.bound.respond_to?(:variable) && type_var.bound.variable == arg.variable)
          end
          if matching_var && matching_var.variable == ':?' && matching_var.lower_bound
            matching_var.lower_bound
          elsif matching_var
              # Type variables and generic methods => function will still be generic
            matching_var.bound || matching_var
          else
            #generic_function = true
            #TyUnboundType.new(matching_var.variable, :lower_bound)
            #fail TypeCheckError, "Cannot find matching type var for #{arg.variable} instantiating #{self}", arg.node
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
            #"[#{var_type.variable} <= #{var_type.bound}]"
            "[#{var_type.bound}]"
          else
            "[#{var_type.to_s}]"
          end

        end
        "#{base_string}#{var_types_strings.join}"
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
