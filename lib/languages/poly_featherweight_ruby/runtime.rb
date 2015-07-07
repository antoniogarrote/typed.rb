require_relative('../../../lib/type_signature/parser')
require_relative('./types')

class Integer
  # ts '#+ / Integer -> Integer'
  def +(other)
    raise StandardError.new('Error invoking abstract method Integer#+')
  end

  # TODO
  # [:+, :-, :*, :/, :**, :~, :&, :|, :^, :[], :<<, :>>, :to_f, :size, :bit_length]
end

class BasicObject

  class TypeRegistry
    class << self
      def registry
        @registry ||= {}
        @registry
      end

      def generic_types_registry
        @generic_types_registry ||= {}
        @generic_types_registry
      end

      def clear
        generic_types_registry.clear
        registry.clear
      end

      def register_type_information(kind, receiver, method, type_ast)
        methods_for(kind, receiver)[method] = type_ast
      end

      def register_generic_type_information(generic_type_information)
        if generic_types_registry[generic_type_information[:type]]
          fail ::TypedRb::Languages::PolyFeatherweightRuby::Types::TypeParsingError,
          "Duplicated generic type definition for #{generic_type_information[:type]}"
        else
          generic_types_registry[generic_type_information[:type]] = generic_type_information
        end
      end

      def object_key(kind, receiver)
        "#{kind}|#{receiver}"
      end

      def methods_for(kind, receiver)
        method_registry = registry[object_key(kind, receiver)] || {}
        registry[object_key(kind, receiver)] = method_registry
        method_registry
      end

      def find_generic_type(type)
        @generic_types_registry[type]
      end

      def find(kind, klass, message)
        class_data = registry[[kind, klass]]
        if class_data
          class_data[message.to_s]
        else
          nil
        end
      end

      def normalize_types!
        normalized = {}
        @registry.each_pair do |kind_receiver, method_signatures|
          parts = kind_receiver.split('|')
          type = parts.take(1).first.to_sym
          klass_name = parts.drop(1).join('_')
          if klass_name == 'main'
            klass = :main
            all_instance_methods = TOPLEVEL_BINDING.public_methods + TOPLEVEL_BINDING.protected_methods + TOPLEVEL_BINDING.private_methods
            all_methods = TOPLEVEL_BINDING.receiver.class.public_methods + TOPLEVEL_BINDING.receiver.class.protected_methods + TOPLEVEL_BINDING.receiver.class.private_methods
          else
            klass = Object.const_get(klass_name)
            all_instance_methods = klass.public_instance_methods + klass.protected_instance_methods + klass.private_instance_methods
            all_methods = klass.public_methods + klass.protected_methods + klass.private_methods
          end
          method_signatures = method_signatures.inject({}) do |signatures_acc, (method, signature)|
            if type == :instance
              unless (all_instance_methods).include?(method.to_sym)
                fail ::TypedRb::Languages::PolyFeatherweightRuby::Types::TypeParsingError,
                     "Declared typed instance method '#{method}' not found for class '#{klass}'"
              end
            elsif type == :class
              unless all_methods.include?(method.to_sym)
                fail ::TypedRb::Languages::PolyFeatherweightRuby::Types::TypeParsingError,
                     "Declared typed class method '#{method}' not found for class '#{klass}'"
              end
            end
            signatures_acc[method] = normalize_signature!(klass,signature)
            signatures_acc
          end
          normalized[[type,klass]] = method_signatures
        end
        @registry = normalized

        normalized_generic_types = {}
        normalized_generic_types = generic_types_registry.inject(normalized_generic_types) do |acc, (_, info)|
          info[:type] = Object.const_get(info[:type])
          info[:parameters] = info[:parameters].map do |parameter|
            ::TypedRb::Languages::PolyFeatherweightRuby::Types::Type.parse(parameter, info[:type])
          end
          acc[info[:type]] = info; acc
        end
        @generic_types_registry = normalized_generic_types
      end

      def normalize_signature!(klass, type)
        ::TypedRb::Languages::PolyFeatherweightRuby::Types::Type.parse(type, klass)
      end
    end
  end

  def ts signature
    if $TYPECHECK
      parametric_type_prefix = /\s*(module|class|type)\s*/
      if signature.index(parametric_type_prefix) == 0
        type_signature = signature.split(parametric_type_prefix).last
        generic_type = ::TypedRb::TypeSignature::Parser.parse(type_signature).first
        TypeRegistry.register_generic_type_information(generic_type)
      else
        method, signature = signature.split(/\s+\/\s+/)

        kind, receiver, message = if method.index('#')
                                    [:instance] + method.split('#')
                                  elsif method.index('.')
                                    [:class] + method.split('.')
                                  else
                                    fail ::TypedRb::Languages::PolyFeatherweightRuby::Types::TypeParsingError,
                                    "Error parsing receiver, method signature: #{signature}"
                                  end

        if receiver == ''
          if self.object_id == ::TOPLEVEL_BINDING.receiver.object_id
            receiver = :main
          elsif self.instance_of?(::Class)
            receiver = self.name
          else
            receiver = self.class.name
          end
        end

        kind = :"#{kind}_variable" if message.index('@')

        type_ast = ::TypedRb::TypeSignature::Parser.parse(signature)

        TypeRegistry.register_type_information(kind, receiver, message, type_ast)
      end
    end
  end
end
