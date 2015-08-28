require_relative '../runtime'

class BasicObject
  class TypeRegistry
    class << self
      ts '.clear / -> unit'
      def clear
        generic_types_registry.clear
        generic_types_parser_registry.clear
        registry.clear
        parser_registry.clear
      end

      ts '.register_type_information / Symbol -> String -> String -> Object -> unit'
      def register_type_information(kind, receiver, method, type_ast)
        methods_for(kind, receiver)[method] = type_ast
      end

      ts '.register_generic_type_information / Hash[Object][Object] -> unit'
      def register_generic_type_information(generic_type_information)
        if generic_types_parser_registry[generic_type_information[:type]]
          fail ::TypedRb::Types::TypeParsingError,
          "Duplicated generic type definition for #{generic_type_information[:type]}"
        else
          generic_types_parser_registry[generic_type_information[:type]] = generic_type_information
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
          Array.(TypedRb::Types::Polymorphism::TypeVariable).new
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
      ts '.find / Symbol -> Class -> String -> TypedRb::Types::TyFunction'
      def find(kind, klass, message)
        class_data = registry[[kind, klass]]
        if class_data
          # TODO: What should we when the class is in the registry but the method is missing?
          # The class has been typed but only partially?
          # Dynamic invocation or error?
          # Maybe an additional @dynamic annotation can be added to distinguish the desired outcome.
          # Preferred outcome right now is nil to catch errors in unification, safer assumption.
          # class_data[message.to_s] || nil # ::TypedRb::Types::TyDynamicFunction.new(klass, message)
          class_data[message.to_s] || ::TypedRb::Types::TyDynamicFunction.new(klass, message)
        elsif kind == :instance_variable || kind == :class_variable
          nil
        else
          # if registered?(klass)
          #   nil
          # else
          ::TypedRb::Types::TyDynamicFunction.new(klass, message)
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

      ts '.normalize_generic_types! / -> unit'
      def normalize_generic_types!
        initial_value = Hash.(Class, TypedRb::Types::TyGenericSingletonObject).new
        @generic_types_registry = generic_types_parser_registry.each_with_object(initial_value) do |type_info, acc|
          _, info = type_info
          info[:type] = Object.const_get(info[:type])
          TypedRb.log(binding, :debug,  "Normalising generic type: #{info[:type]}")

          info[:parameters] = info[:parameters].map do |parameter|
            ::TypedRb::Types::Type.parse(parameter, info[:type])
          end
          acc[info[:type]] = ::TypedRb::Types::TyGenericSingletonObject.new(info[:type], info[:parameters])
        end
      end

      ts '.normalize_methods! / -> unit'
      def normalize_methods!
        @registry = {}
        parser_registry.each_pair do |kind_receiver, method_signatures|
          parts = kind_receiver.split('|')
          type = parts.take(1).first.to_sym
          klass_name = parts.drop(1).join('_')
          if klass_name == 'main'
            klass = :main
            all_instance_methods = TOPLEVEL_BINDING.public_methods +
                                   TOPLEVEL_BINDING.protected_methods +
                                   TOPLEVEL_BINDING.private_methods
            all_methods = TOPLEVEL_BINDING.receiver.class.public_methods +
                          TOPLEVEL_BINDING.receiver.class.protected_methods +
                          TOPLEVEL_BINDING.receiver.class.private_methods
          else
            klass = Object.const_get(klass_name)
            all_instance_methods = klass.public_instance_methods + klass.protected_instance_methods + klass.private_instance_methods
            all_methods = klass.public_methods + klass.protected_methods + klass.private_methods
          end

          method_signatures = method_signatures.each_with_object({}) do |method_info, signatures_acc|
            method, signature = method_info
            TypedRb.log(binding, :debug, "Normalizing method #{type}[#{klass}] :: #{method} / #{signature}")

            if type == :instance
              unless (all_instance_methods).include?(method.to_sym)
                fail ::TypedRb::Types::TypeParsingError,
                "Declared typed instance method '#{method}' not found for class '#{klass}'"
              end
            elsif type == :class
              unless all_methods.include?(method.to_sym)
                fail ::TypedRb::Types::TypeParsingError,
                "Declared typed class method '#{method}' not found for class '#{klass}'"
              end
            end
            signatures_acc[method] = normalize_signature!(klass, signature)
            if (type != :class_variable && type != :instance_variable) && !signatures_acc[method].is_a?(TypedRb::Types::TyFunction)
              fail ::TypedRb::Types::TypeParsingError,
              "Error parsing receiver, method signature: #{type}[#{klass}] :: '#{method}', function expected, got '#{signatures_acc[method]}'"
            end
          end
          @registry[[type, klass]] = method_signatures
        end
      end

      ts '.normalize_signature! / Class -> String -> TypedRb::Types::TyFunction'
      def normalize_signature!(klass, type)
        ::TypedRb::Types::Type.parse(type, klass)
      end

      ts '.object_key / String -> String -> String'
      def object_key(kind, receiver)
        "#{kind}|#{receiver}"
      end
    end
  end
end
