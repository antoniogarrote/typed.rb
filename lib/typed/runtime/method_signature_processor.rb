module TypedRb
  module Runtime
    class MethodSignatureProcessor
      class << self
        def process(full_signature, base_object)
          kind, receiver, message, type_signature = destruct_signature(full_signature)
          receiver = parse_implicit_receiver(base_object) if receiver.empty?
          message, method_type_variables = parse_method_type_variable(message)

          type_ast = ::TypedRb::TypeSignature::Parser.parse(type_signature, method_type_variables)
          BasicObject::TypeRegistry.register_type_information(kind, receiver, message, type_ast)
        end

        private

        def destruct_signature(full_signature)
          parts = full_signature.split(%r{\s*/\s*})
          type_signature = parts.pop
          receiver_and_message = parts.join('/')
          if receiver_and_message.index('#')
            kind = :instance
            receiver, message =  receiver_and_message.split('#')
          elsif receiver_and_message.index('.')
            kind = :class
            receiver, message = receiver_and_message.split('.')
          else
            fail ::TypedRb::Types::TypeParsingError, "Error parsing receiver, method type_signature: #{full_signature}"
          end
          kind = :"#{kind}_variable" if message.index('@')
          [kind, receiver, message, type_signature]
        end

        def parse_implicit_receiver(base_object)
          return 'main' if top_level?(base_object)
          return parse_class_implicit_receiver(base_object) if class_or_module?(base_object)
          base_object.class.name # instance object
        end

        def top_level?(base_object)
          base_object.object_id == ::TOPLEVEL_BINDING.receiver.object_id
        end

        def class_or_module?(base_object)
          base_object.instance_of?(::Class) || base_object.instance_of?(::Module)
        end

        def parse_class_implicit_receiver(base_object)
          if base_object.name.nil?
            # singleton classes
            base_object.to_s.match(/Class:(.*)>/)[1]
          else
            base_object.name
          end
        end

        def parse_method_type_variable(message)
          type_variables = message.scan(/(\[\w+(\s*[<>]\s*\w+)?\])/).map(&:first).map do |var|
            ::TypedRb::TypeSignature::Parser.parse(var)
          end
          message = message.split(/\[[\w]+/).first

          method_type_var_info = type_variables.each_with_object(::Hash.call(::String, 'Hash[Symbol][String]').new) do |variable, acc|
            var_name = variable[:type]
            variable[:type] = "#{message}:#{var_name}"
            acc[var_name] = variable
          end
          [message, method_type_var_info]
        end
      end
    end
  end
end
