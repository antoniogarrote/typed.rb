require_relative './ty_function'

module TypedRb
  module Types

    class TyDynamic < TyObject
      def compatible?(other_type, relation = :lt)
        true
      end
    end

    class TyDynamicFunction < TyFunction
      def initialize(klass, message, with_block = true)
        super([], TyDynamic.new(Object))
        @klass = klass
        @message = message
        @block_type = TyDynamicFunction.new(Proc, :cal, false) if with_block
      end

      def check_args_application; end

      def compatible?(other_type, relation = :lt)
        true
      end
    end
  end
end
