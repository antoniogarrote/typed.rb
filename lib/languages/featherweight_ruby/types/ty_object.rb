module TypedRb
  module Languages
    module FeatherweightRuby
      module Types
        class TyObject < Type

          attr_reader :hierarchy, :classes, :modules, :ruby_type

          def initialize(ruby_type)
            @ruby_type = ruby_type
            @hierarchy = ruby_type.ancestors
            @classes = @hierarchy.detect{|klass| klass.instance_of?(Class) }
            @modules = @hierarchy.detect{|klass| klass.instance_of?(Module) }
          end

          def compatible?(other_type)
            if other_type.is_a?(TyObject)
              @hierarchy.include?(other_type.ruby_type)
            else
              other_type.compatible?(self)
            end
          end

          def as_object_type
            self
          end


          def find_function_type(message)
            BasicObject::TypeRegistry.find(:instance, ruby_type, message)
          end

          def find_var_type(var)
            BasicObject::TypeRegistry.find(:instance_var, ruby_type, var)
          end

          def resolve_ruby_method(message)
            @ruby_type.instance_method(message)
          end

          def to_s
            @ruby_type.name
          end
        end
      end
    end
  end
end