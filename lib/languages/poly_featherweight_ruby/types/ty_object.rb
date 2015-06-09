module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Types
        class TyObject < Type

          attr_reader :hierarchy, :classes, :modules, :ruby_type

          def initialize(ruby_type, classes=[], module=[])
            if ruby_type
              @ruby_type = ruby_type
              @hierarchy = ruby_type.ancestors
              @classes = @hierarchy.detect{|klass| klass.instance_of?(Class) }
              @modules = @hierarchy.detect{|klass| klass.instance_of?(Module) }
              @with_ruby_type = true
            else
              @ruby_type = Object
              @classes = @classes
              @modules = @modules
              @hierarchy = @modules + @classes
              @with_ruby_type = false
            end
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
            variable = "#{ruby_type}::#{var}"
            TypedRb::Languages::PolyFeatherweightRuby::Types::TypingContext.type_variable_for(:instance_variable, variable)
          end

          def resolve_ruby_method(message)
            @ruby_type.instance_method(message)
          end

          def to_s
            if @with_ruby_type
              @ruby_type.name
            else
              "#{@classes.first.to_s} with [#{@modules.map(&:to_s).join(',')}]"
            end
          end

          def join(other_type)
            this_classes = classes.reverse
            other_classes = other_type.classes.reverse
            
          end
        end
      end
    end
  end
end
