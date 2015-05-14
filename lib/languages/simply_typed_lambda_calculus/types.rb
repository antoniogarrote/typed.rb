module TypedRb
  module Languages
    module SimplyTypedLambdaCalculus
      module Types

        TYPE_REGISTRY = {}

        class TypingContext
          def initialize(parent=nil)
            @parent = parent
            @bindings = {}
          end

          def add_binding(val,type)
            TypingContext.new(self).push_binding(val,type)
          end

          def get_type_for(val)
            type = @bindings[val]
            if type.nil?
              @parent.get_type_for(val) if @parent
            else
              type
            end
          end

          protected

          def push_binding(val,type)
            @bindings[val] = type
            self
          end
        end

        class Type
          def self.parse(type)
            return nil if type.nil?
            if type.instance_of?(Array)
              from,to = [type.first,type.last]
              parse_function_type(from,to)
            else
              parse_atomic_type(type)
            end
          end

          def compatible?(other_type)
            if other_type.instance_of?(Class)
              self.instance_of?(other_type)
            else
              other_type.instance_of?(self.class)
            end
          end

          protected

          def self.parse_atomic_type(type)
            parsed_type = TYPE_REGISTRY[type]
            if(parsed_type.nil?)
              #puts "ERROR"
              #puts type
              #puts type.inspect
              #puts "==========================================="
              raise StandardError, "Uknown type #{type}"
            else
              parsed_type.new
            end
          end

          def self.parse_function_type(from,to)
            TyFunction.new(parse(from),parse(to))
          end
        end

        class TyInteger < Type
          def initialize
          end

          def to_s
            "Int"
          end
        end
        TYPE_REGISTRY['Int'] = TyInteger

        class TyBoolean < Type
          def initialize
          end

          def to_s
            "Bool"
          end
        end
        TYPE_REGISTRY['Bool'] = TyBoolean

        class TyFunction < Type
          attr_accessor :from, :to
          def initialize(from,to)
            @from = from
            @to = to
          end

          def to_s
            if @to.nil?
              "#{@from}"
            else
              "(#{@from} -> #{@to})"
            end
          end
        end
      end
    end
  end
end
