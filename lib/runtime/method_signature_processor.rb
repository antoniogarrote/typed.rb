module TypedRb
  module Runtime
    class MethodSignatureProcessor
      def self.process(signature, base_object)
        method, signature = signature.split(%r{\s*/\s*})
        if method.index('#')
          kind = :instance
          receiver, message =  method.split('#')
        elsif method.index('.')
          kind = :class
          receiver, message = method.split('.')
        else
          fail ::TypedRb::Types::TypeParsingError, "Error parsing receiver, method signature: #{signature}"
        end

        if receiver == ''
          if object_id == ::TOPLEVEL_BINDING.receiver.object_id
            receiver = 'main'
          elsif base_object.instance_of?(::Class) || base_object.instance_of?(::Module)
            receiver = if base_object.name.nil?
                         # singleton classes
                         base_object.to_s.match(/Class:(.*)>/)[1]
                       else
                         base_object.name
                       end
          else
            receiver = base_object.class.name
          end
        end

        kind = :"#{kind}_variable" if message.index('@')
        method_variables = message.scan(/(\[\w+\])/).flatten.map do |var|
          ::TypedRb::TypeSignature::Parser.parse(var)
        end

        message = message.split(/\[[\w]+/).first
        method_var_info = method_variables.each_with_object(::Hash.(::String, 'Hash[Symbol][String]').new) do |variable, acc|
          var_name = variable[:type]
          variable[:type] = "#{message}:#{var_name}"
          acc[var_name] = variable
        end
        type_ast = ::TypedRb::TypeSignature::Parser.parse(signature, method_var_info)
        BasicObject::TypeRegistry.register_type_information(kind, receiver, message, type_ast)
      end
    end
  end
end
