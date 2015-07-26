require_relative './ty_function'

module TypedRb
  module Types

    class TyUnboundType

      attr_reader :variable_name, :bound_type

      def initialize(variable_name, bound_type)
        @variable_name = variable_name
        @bound_type
      end

      def dynamic?
        false
      end

      def defaults_to_dynamic?
        false
      end

      def compatible?(other_type, relation = :lt)
        error_message = "Comparing unbound variable #{variable_name} (#{bound_type}) with #{other_type}, relation #{relation}"
        fail UncomparableTypes, error_message
      end

      def as_object_type
        self
      end
    end
  end
end
