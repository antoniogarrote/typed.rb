module TypedRb
  module Languages
    module FeatherweightRuby
      module Types

        class TypeParsingError < StandardError; end

        class TypingContext
          def initialize(parent=nil)
            @parent = parent
            @bindings = {}
          end

          def add_binding(val,type)
            TypingContext.new(self).push_binding(val,type)
          end

          def add_binding!(val,type)
            push_binding(val,type)
          end

          def get_type_for(val)
            type = @bindings[val]
            if type.nil?
              @parent.get_type_for(val) if @parent
            else
              type
            end
          end

          def get_self
            @bindings[:self]
          end

          protected

          def push_binding(val,type)
            @bindings[val] = type
            self
          end
        end

        class Type
          def self.parse(type)
            fail TypeParsingError, 'Error parsing type: nil value.' if type.nil?
            if type == 'unit'
              TyUnit.new
            elsif type == 'Bool'
              TyBoolean.new
            elsif type.instance_of?(Array)
              parse_function_type(type)
            else
              parse_object_type(type)
            end
          end

          # other_type is a meta-type not a ruby type
          def compatible?(other_type)
            if other_type.instance_of?(Class)
              self.instance_of?(other_type) || other_type == TyError
            else
              other_type.instance_of?(self.class) || other_type.instance_of?(TyError)
            end
          end

          def self.parse_object_type(type)
            begin
              ruby_type = Object.const_get(type)
              TyObject.new(ruby_type)
            rescue StandardError => e
              puts e.message
              #puts "ERROR"
              #puts type
              #puts type.inspect
              #puts "==========================================="
              fail TypeParsingError, "Unknown Ruby type #{type}"
            end
          end

          def self.parse_singleton_object_type(type)
            begin
              ruby_type = Object.const_get(type)
              TySingletonObject.new(ruby_type)
            rescue StandardError => e
              puts e.message
              #puts "ERROR"
              #puts type
              #puts type.inspect
              #puts "==========================================="
              fail TypeParsingError, "Unknown Ruby type #{type}"
            end
          end

          protected

          def self.parse_function_type(arg_types)
            walk_args = ->((head,tail),parsed_arg_types=[]) do
              parsed_arg_types << parse(head)
              if tail.instance_of?(Array)
                walk_args[tail, parsed_arg_types]
              elsif tail != nil
                parsed_arg_types + [parse(tail)]
              end
            end

            parsed_arg_types = walk_args[arg_types]
            return_type = parsed_arg_types.pop

            TyFunction.new(parsed_arg_types, return_type)
          end
        end

        class TyUnit < Type
          def to_s
            'unit'
          end
        end

        class TyObject < Type

          attr_reader :hierarchy, :classes, :modules, :ruby_type

          def initialize(ruby_type)
            @ruby_type = ruby_type
            @hierarchy = ruby_type.ancestors
            @classes = @hierarchy.detect{|klass| klass.instance_of?(Class) }
            @modules = @hierarchy.detect{|klass| klass.instance_of?(Module) }
          end

          def compatible?(other_type)
            if other_type.instance_of?(TyObject)
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

        class TySingletonObject < TyObject

          def initialize(ruby_type)
            super(ruby_type)
          end

          def find_function_type(message)
            BasicObject::TypeRegistry.find(:class, ruby_type, message)
          end

          def find_var_type(var)
            BasicObject::TypeRegistry.find(:class_var, ruby_type, var)
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

        class TyError < Type
          def to_s
            'error'
          end

          def compatible?(other_type)
            true
          end

          def self.is?(type)
            type == TyError || type.instance_of?(TypeError)
          end
        end

        class TyBoolean < Type
          def to_s
            'Bool'
          end
        end

        class TyFunction < Type
          attr_accessor :from, :to
          def initialize(from,to)
            @from = from
            @to = to
          end

          def to_s
            "(#{@from.map(&:to_s).join(',')} -> #{@to})"
          end

          def can_apply?(arg_types)

          end
        end

        # Aliases for different basic types

        class TyInteger < TyObject
          def initialize
            super(Integer)
          end
        end

        class TyFloat < TyObject
          def initialize
            super(Float)
          end
        end

        class TyString < TyObject
          def initialize
            super(String)
          end
        end
      end
    end
  end
end
