require_relative('../../../lib/type_signature/parser')

class TypeParsingError < StandardError; end

class BasicObject

  class TypeRegistry
    class << self
      def registry
        @registry ||= {}
        @registry
      end

      def register_type_information(kind, receiver, method, type_ast)
        methods_for(kind,receiver)[method] = type_ast
      end

      def object_key(kind,receiver)
        "#{kind}|#{receiver}"
      end

      def methods_for(kind, receiver)
        method_registry = registry[object_key(kind,receiver)] || {}
        registry[object_key(kind,receiver)] = method_registry
        method_registry
      end

      def normalize_types!
        normalized = {}
        @registry.each_pair do |kind_receiver, method_signatures|
          parts = kind_receiver.split('|')
          type = parts.take(1).first.to_sym
          klass = Object.const_get(parts.drop(1).join('_'))
          method_signatures = method_signatures.inject({}) do |signatures_acc, (method, signature)|
            if type == :instance
              unless klass.instance_methods.include?(method.to_sym)
                fail ::TypeParsingError, "Declared typed instance method '#{method}' not found for class '#{klass}'"
              end
            elsif type == :class
              unless klass.methods.include?(method.to_sym)
                fail ::TypeParsingError, "Declared typed class method '#{method}' not found for class '#{klass}'"
              end
            end
            signatures_acc[method] = normalize_signature!(signature)
            signatures_acc
          end
          normalized[[type,klass]] = method_signatures
        end
        @registry = normalized
      end

      def normalize_signature!(type)
        if type.instance_of?(Array)
          [normalize_signature!(type.first), normalize_signature!(type.last)]
        else
          if type == 'unit'
            :unit
          elsif type == 'Bool'
            :bool
          else
            Object.const_get(type)
          end
        end
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
                                  fail ::TypeParsingError, "Error parsing receiver, method signature: #{signature}"
                                end

      receiver = self.name if receiver == ''


      kind = :"#{kind}_variable" if message.index('@')

      type_ast = ::TypedRb::TypeSignature::Parser.parse(signature)

      TypeRegistry.register_type_information(kind, receiver, message, type_ast)
    end
  end

end