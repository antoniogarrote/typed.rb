require_relative '../model'

module TypedRb
  module Model
    # A constant expression
    class TmConst < Expr
      attr_reader :val

      def initialize(val, node)
        super(node)
        @val = val
      end

      def rename(_from_binding, _to_binding)
        self
      end

      def check_type(_context)
        value = Object.const_get(@val)
        type = if value.instance_of?(Class)
                 Runtime::TypeParser.parse_singleton_object_type(value.name)
               elsif value.instance_of?(Module)
                 Runtime::TypeParser.parse_existential_object_type(value.name)
               else
                 # Must be a user defined constant
                 Runtime::TypeParser.parse_object_type(value.receiver.class.name)
               end
        type.node = node
        type
      end
    end
  end
end
