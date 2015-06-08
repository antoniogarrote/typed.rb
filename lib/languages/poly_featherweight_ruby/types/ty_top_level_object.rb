module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Types
        class TyTopLevelObject < TyObject

          def initialize
            super(TOPLEVEL_BINDING.receiver.class)
          end

          def compatible?(other_type)
            fail 'invoking compatible? in the top level object'
          end

          def as_object_type
            self
          end

          def find_function_type(message)
            BasicObject::TypeRegistry.find(:instance, :main, message)
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
  end
end
