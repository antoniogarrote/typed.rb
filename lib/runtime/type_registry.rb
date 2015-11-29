require_relative '../runtime'

class BasicObject
  class TypeRegistry
    class << self
      include TypedRb::Runtime::Normalization

      ts '.clear / -> unit'
      def clear
        generic_types_registry.clear
        generic_types_parser_registry.clear
        registry.clear
        parser_registry.clear
      end

      ts '.register_type_information / Symbol -> String -> String -> Object -> unit'
      def register_type_information(kind, receiver, method, type_ast)
        methods = methods_for(kind, receiver)[method] || []
        methods << type_ast
        methods_for(kind, receiver)[method] = methods
      end

      ts '.register_generic_type_information / Hash[Object][Object] -> Hash[Object][Object] -> unit'
      def register_generic_type_information(generic_type_information, generic_super_type_information)
        unless generic_type_information.is_a?(String) # TODO: String when super annotations for non-generic types
          generic_type_information[:super_type] = generic_super_type_information
          if generic_types_parser_registry[generic_type_information[:type]]
            fail ::TypedRb::Types::TypeParsingError,
            "Duplicated generic type definition for #{generic_type_information[:type]}"
          else
            generic_types_parser_registry[generic_type_information[:type]] = generic_type_information
          end
        end
      end

      def find_existential_type(type)
        existential_type = existential_types_registry[type]
        if existential_type.nil?
          existential_type = TypedRb::Types::TyExistentialType.new(type)
          @existential_types_registry[type] = existential_type
        end
        existential_type
      end

      ts '.find_generic_type / Class -> TypedRb::Types::TyGenericSingletonObject'
      def find_generic_type(type)
        @generic_types_registry[type]
      end

      ts '.type_vars_for / Class -> Array[TypedRb::Types::Polymorphism::TypeVariable]'
      def type_vars_for(klass)
        singleton_object = find_generic_type(klass)
        if singleton_object
          singleton_object.type_vars.map do |type_var|
            ::TypedRb::Types::Polymorphism::TypeVariable.new(type_var.variable,
                                                             :upper_bound => type_var.upper_bound,
                                                             :lower_bound => type_var.lower_bound,
                                                             :gen_name => false)
          end
        else
          Array.call(TypedRb::Types::Polymorphism::TypeVariable).new
        end
      end

      ts '.type_var? / Class -> String -> Boolean'
      def type_var?(klass, variable)
        singleton_object = generic_types_registry[klass]
        if singleton_object
          singleton_object.type_vars.any? do |type_var|
            type_var.variable == variable
          end
        else
          false
        end
      end

      # TODO: Generic types are retrieved without enforcing type constraints
      # because they haven't been materialised.
      ts '.find / Symbol -> Class -> String -> Array[TypedRb::Types::TyFunction]'
      def find(kind, klass, message)
        class_data = registry[[kind, klass]]
        if class_data
          # TODO: What should we when the class is in the registry but the method is missing?
          # The class has been typed but only partially?
          # Dynamic invocation or error?
          # Maybe an additional @dynamic annotation can be added to distinguish the desired outcome.
          # Preferred outcome right now is nil to catch errors in unification, safer assumption.
          # class_data[message.to_s] || nil # ::TypedRb::Types::TyDynamicFunction.new(klass, message)
          class_data[message.to_s] || [::TypedRb::Types::TyDynamicFunction.new(klass, message)]
        elsif kind == :instance_variable || kind == :class_variable
          nil
        else
          # if registered?(klass)
          #   nil
          # else
          [::TypedRb::Types::TyDynamicFunction.new(klass, message)]
          # end
        end
      end

      ts '.registered? / Class -> Boolean'
      def registered?(klass)
        registry.keys.map(&:last).include?(klass)
      end

      ts '.normalize_types! / -> unit'
      def normalize_types!
        normalize_generic_types!
        normalize_methods!
      end

      protected

      ts '.registry / -> Hash[ Array[Object] ][ Hash[String][TypedRb::Types::TyFunction] ]'
      def registry
        @registry ||= {}
        @registry
      end

      def existential_types_registry
        @existential_types_registry ||= {}
      end

      ts '.generic_types_registry / -> Hash[Class][ TypedRb::Types::TyGenericSingletonObject ]'
      def generic_types_registry
        @generic_types_registry ||= {}
        @generic_types_registry
      end

      ts '.parser_registry / -> Hash[ String ][ Hash[String][Object] ]'
      def parser_registry
        @parser_registry ||= {}
        @parser_registry
      end

      ts '.generic_types_parser_registry / -> Hash[String][ Hash[Object][Object] ]'
      def generic_types_parser_registry
        @generic_types_parser_registry ||= {}
        @generic_types_parser_registry
      end

      ts '.methods_for / Symbol -> String -> Hash[String][Object]'
      def methods_for(kind, receiver)
        method_registry = parser_registry[object_key(kind, receiver)] || {}
        parser_registry[object_key(kind, receiver)] = method_registry
        method_registry
      end
    end
  end
end
