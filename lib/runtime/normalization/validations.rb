module TypedRb
  module Runtime
    module Normalization
      module Validations
        def validate_signature(type, normalized_signature)
          return if type == :class_variable || type == :instance_variable
          return if normalized_signature.is_a?(TypedRb::Types::TyFunction)
          fail ::TypedRb::Types::TypeParsingError,
               "Error parsing receiver, method signature: #{type}[#{klass}] :: '#{method}', function expected, got '#{signatures_acc[method]}'"
        end

        def validate_method(class_methods_info, klass, method, method_type)
          if method_type == :instance
            unless (class_methods_info[:instance_methods]).include?(method.to_sym)
              fail ::TypedRb::Types::TypeParsingError,
                   "Declared typed instance method '#{method}' not found for class '#{klass}'"
            end
          elsif method_type == :class
            unless class_methods_info[:all_methods].include?(method.to_sym)
              fail ::TypedRb::Types::TypeParsingError,
                   "Declared typed class method '#{method}' not found for class '#{klass}'"
            end
          end
        end
      end
    end
  end
end