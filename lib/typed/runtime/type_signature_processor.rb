module TypedRb
  module Runtime
    class TypeSignatureProcessor
      PARAMETRIC_TYPE_PREFIX = /\s*(module|class|type)\s*/
      class << self
        def type_signature?(signature)
          signature.index(PARAMETRIC_TYPE_PREFIX) == 0
        end

        def process(signature)
          type_signature = signature.split(PARAMETRIC_TYPE_PREFIX).last

          type_signature, super_type_signatures = parse_generic_supertype(type_signature)

          generic_type = ::TypedRb::TypeSignature::Parser.parse(type_signature)
          if super_type_signatures
            generic_super_types = super_type_signatures.split(/\s*,\s*/).map do |super_type_signature|
              ::TypedRb::TypeSignature::Parser.parse(super_type_signature)
            end
          end

          BasicObject::TypeRegistry.register_generic_type_information(generic_type, generic_super_types)
        end

        private

        # Generic types can have an explicit generic supertype.
        # e.g:
        # ts 'type Pair[S][T] super Array[Object]'
        def parse_generic_supertype(type_signature)
          type_signature.split(/\s*super\s*/)
        end
      end
    end
  end
end
