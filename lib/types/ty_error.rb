module TypedRb
  module Types
    class TyError < Type
      def to_s
        'error'
      end

      def compatible?(_relation, _other_type = :lt)
        true
      end

      def self.is?(type)
        type == TyError || type.is_a?(TyError)
      end
    end
  end
end
