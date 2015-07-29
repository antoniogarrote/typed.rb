module TypedRb
  module Types
    class TyTopLevelObject < TyObject

      def initialize
        super(TOPLEVEL_BINDING.receiver.class)
      end

      def compatible?(other_type)
        fail StandardError, 'invoking compatible? in the top level object'
      end

      def as_object_type
        self
      end

      def find_function_type(message)
        found_type = BasicObject::TypeRegistry.find(:instance, :main, message)
        if found_type && !found_type.is_a?(TyDynamicFunction)
          [:main, found_type]
        else
          TyObject.new(ruby_type).find_function_type(message)
        end
      end

      def find_var_type(var)
        BasicObject::TypeRegistry.find(:instance_variable, :main, var)
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
