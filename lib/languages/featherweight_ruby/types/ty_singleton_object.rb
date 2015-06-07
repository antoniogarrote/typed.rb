module TypedRb
  module Languages
    module FeatherweightRuby
      module Types
        class TySingletonObject < TyObject

          def initialize(ruby_type)
            super(ruby_type)
          end

          def find_function_type(message)
            BasicObject::TypeRegistry.find(:class, ruby_type, message)
          end

          def find_var_type(var)
            BasicObject::TypeRegistry.find(:class_variable, ruby_type, var)
          end

          def resolve_ruby_method(message)
            @ruby_type.singleton_method(message)
          end

          def as_object_type
            TyObject.new(ruby_type)
          end

          def to_s
            "Class[#{@ruby_type.name}]"
          end
        end
      end
    end
  end
end