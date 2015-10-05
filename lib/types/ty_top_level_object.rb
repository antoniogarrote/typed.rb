module TypedRb
  module Types
    class TyTopLevelObject < TyObject

      def initialize
        super(TOPLEVEL_BINDING.receiver.class)
      end

      def compatible?(_other_type)
        fail StandardError, 'invoking compatible? in the top level object'
      end

      def as_object_type
        self
      end

      def find_function_type(message, num_args, block)
        found_type = select_matching_function_in_class(:main, :instance, message, num_args, block)
        if found_type && !found_type.is_a?(TyDynamicFunction)
          [:main, found_type]
        else
          TyObject.new(ruby_type, node).find_function_type(message, num_args, block)
        end
      end

      def find_var_type(var)
        super(var, :main)
      end

      def resolve_ruby_method(message)
        @ruby_type.method(message)
      end

      def to_s
        'Object[\'main\']'
      end
    end
  end
end
