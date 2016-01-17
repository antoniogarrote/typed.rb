module TypedRb
  module Types
    class TySingletonObject < TyObject
      def initialize(ruby_type, node = nil)
        # super(ruby_type.class)
        # @ruby_type = ruby_type
        super(ruby_type, node)
      end

      # No generic type, function will always be concrete
      def find_function_type(message, num_args, block)
        maybe_function = select_matching_function_in_class(ruby_type, :class, message, num_args, block)
        if maybe_function && !maybe_function.dynamic?
          [ruby_type, maybe_function]
        else
          # This object is a class, we need to look in the hierarhcy of the meta-class
          find_function_type_in_metaclass_hierarchy(message, num_args, block)
        end
      end

      def find_function_type_in_metaclass_hierarchy(message, num_args, block)
        hierarchy = Class.ancestors
        initial_value = select_matching_function_in_class(hierarchy.first, :instance, message, num_args, block)
        hierarchy.drop(1).inject([hierarchy.first, initial_value]) do |(klass, acc), type|
          if acc.nil? || acc.is_a?(TyDynamicFunction)
            maybe_function = select_matching_function_in_class(type, :instance, message, num_args, block)
            [type, (maybe_function || TyDynamicFunction.new(klass, message))]
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

      def compatible?(other_type, relation = :lt)
        if other_type.is_a?(TySingletonObject)
          if ruby_type == Class || other_type.ruby_type == Class
            if relation == :gt
              Class.ancestors.include(ruby_type)
            elsif relation == :lt
              Class.ancestors.include?(other_type.ruby_type)
            end
          else
            super(other_type, relation)
          end
        else
          super(other_type, relation)
        end
      end

      def resolve_ruby_method(message)
        @ruby_type.singleton_method(message)
      end

      def as_object_type
        TyObject.new(ruby_type, node)
      end

      def singleton?
        true
      end

      def to_s
        @ruby_type.name
      end
    end
  end
end
