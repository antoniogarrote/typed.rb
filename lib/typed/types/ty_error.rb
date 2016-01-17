module TypedRb
  module Types
    class TyError < Type
      def initialize(node = nil)
        super(node)
      end

      def to_s
        'error'
      end

      def compatible?(_relation, _other_type = :lt)
        true
      end

    end
  end
end
