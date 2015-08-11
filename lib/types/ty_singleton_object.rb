module TypedRb
  module Types
    class TySingletonObject < TyObject

      def initialize(ruby_type, node = nil)
        #super(ruby_type.class)
        #@ruby_type = ruby_type
        super(ruby_type, node)
      end

      # No generic type, function will always be concrete
      def find_function_type(message)
        maybe_function = BasicObject::TypeRegistry.find(:class, ruby_type, message)
        if maybe_function && !maybe_function.dynamic?
          [ruby_type, maybe_function]
        else
          # This object is a class, we need to look in the hierarhcy of the meta-class
          find_function_type_in_metaclass_hierarchy(message)
        end
      end

      def find_function_type_in_metaclass_hierarchy(message)
        hierarchy = Class.ancestors
        initial_value = BasicObject::TypeRegistry.find(:instance, hierarchy.first, message)
        hierarchy.drop(1).inject([hierarchy.first, initial_value]) do |(klass, acc), type|
          if acc.nil? || acc.is_a?(TyDynamicFunction)
            [type, BasicObject::TypeRegistry.find(:instance, type, message)]
          else
            [klass, acc]
          end
        end
      end

      def find_var_type(var)
        var_type = BasicObject::TypeRegistry.find(:class_variable, ruby_type, var)
        if var_type
          var_type
        else
          var_type = Types::TypingContext.type_variable_for(:class_variable, var, hierarchy)
          var_type.node = node
          var_type
        end
      end

      def resolve_ruby_method(message)
        @ruby_type.singleton_method(message)
      end

      def as_object_type
        TyObject.new(ruby_type, node)
      end

      def to_s
        "Class[#{@ruby_type.name}]"
      end
    end
  end
end
