module TypedRb
  module Languages
    module SimplyTypedLambdaCalculus
      module Types

        TYPE_REGISTRY = {}

        class Type
          def self.parse(type)
            case type.type
            when :array
              # array -> hash
              parse(type.children[0])
            when :hash
              from,to = type.children.first.children
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
            # (const [nil, :Type])
            type_name = type.children[1]
            parsed_type = TYPE_REGISTRY[type_name]
            if(parsed_type.nil?)
              puts "ERROR"
              puts type
              puts type.inspect
              puts "==========================================="
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
        TYPE_REGISTRY[:Int] = TyInteger

        class TyBoolean < Type
          def initialize
          end

          def to_s
            "Bool"
          end
        end
        TYPE_REGISTRY[:Bool] = TyBoolean

        class TyFunction < Type
          attr_accessor :from, :to
          def initialize(from,to)
            @from = from
            @to = to
          end

          def to_s
            "(#{@from} -> #{@to})"
          end
        end
      end
    end
  end
end
