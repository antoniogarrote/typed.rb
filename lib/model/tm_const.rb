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
        value_ruby_type = Types::TypingContext.find_namespace(@val)
        type = if value_ruby_type.instance_of?(Class)
                 Runtime::TypeParser.parse_singleton_object_type(value_ruby_type.name)
               elsif value_ruby_type.instance_of?(Module)
                 Runtime::TypeParser.parse_existential_object_type(value_ruby_type.name)
               else
                 # Must be a user defined constant
                 Types::TyObject.new(value_ruby_type.class)
               end
        type.node = node
        type
      end
    end
  end
end
