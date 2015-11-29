module TypedRb
  module Types
    class TyStackJump < TyUnit
      attr_reader :jump_kind, :wrapped_type
      def initialize(jump_kind, wrapped_type, node=nil)
        super(node)
        @jump_kind = jump_kind
        @wrapped_type = wrapped_type
      end

      def stack_jump?
        true
      end

      def self.return(return_type, node = nil)
        TyStackJump.new(:return, return_type, node)
      end

      def self.break(return_type, node = nil)
        TyStackJump.new(:break, return_type, node)
      end

      def return?
        jump_kind == :return
      end

      def break?
        jump_kind == :break
      end
    end
  end
end
