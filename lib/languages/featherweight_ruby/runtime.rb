require_relative('../../../lib/type_signature/parser')
require_relative('./types')

class BasicObject

  class TypeRegistry
    class << self
      def registry
        @registry ||= {}
        @registry
      end

      def register_type_information(kind, receiver, method, type_ast)
        methods_for(kind, receiver)[method] = type_ast
      end

      def object_key(kind, receiver)
        "#{kind}|#{receiver}"
      end

      def methods_for(kind, receiver)
        method_registry = registry[object_key(kind, receiver)] || {}
        registry[object_key(kind, receiver)] = method_registry
        method_registry
      end

      def find(kind, klass, message)
        registry[[kind, klass]][message.to_s]
      rescue Exception => e
        raise e
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
            is_function = if type == :instance
                            unless (all_instance_methods).include?(method.to_sym)
                              fail ::TypedRb::Languages::FeatherweightRuby::Types::TypeParsingError,
                                   "Declared typed instance method '#{method}' not found for class '#{klass}'"
                            end
                            true
                          elsif type == :class
                            unless all_methods.include?(method.to_sym)
                              fail ::TypedRb::Languages::FeatherweightRuby::Types::TypeParsingError,
                                   "Declared typed class method '#{method}' not found for class '#{klass}'"
                            end
                            true
                          else
                            false
                          end
            signatures_acc[method] = normalize_signature!(signature, is_function)
            signatures_acc
          end
          normalized[[type,klass]] = method_signatures
        end
        @registry = normalized
      end

      def normalize_signature!(type, is_function)
        ::TypedRb::Languages::FeatherweightRuby::Types::Type.parse(type, is_function)
      end
    end
  end

  def ts signature
    if $TYPECHECK
      method, signature = signature.split(/\s+\/\s+/)

      kind, receiver, message = if method.index('#')
                                  [:instance] + method.split('#')
                                elsif method.index('.')
                                  [:class] + method.split('.')
                                else
                                  fail ::TypedRb::Languages::FeatherweightRuby::Types::TypeParsingError,
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
