module TypedRb
  module Runtime
    class TypeSignatureProcessor
      PARAMETRIC_TYPE_PREFIX = /\s*(module|class|type)\s*/

      def self.type_signature?(signature)
        signature.index(PARAMETRIC_TYPE_PREFIX) == 0
      end

      def self.process(signature)
        type_signature = signature.split(PARAMETRIC_TYPE_PREFIX).last
        generic_type = ::TypedRb::TypeSignature::Parser.parse(type_signature)
        BasicObject::TypeRegistry.register_generic_type_information(generic_type)
      end
    end
  end
end
