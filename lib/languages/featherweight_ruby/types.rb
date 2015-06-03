module TypedRb
  module Languages
    module FeatherweightRuby
      module Types

        class TypeParsingError < StandardError; end

        class TypingContext

          def self.top_level
            TypingContext.new.add_binding!(:self, TyTopLevelObject.new)
          end

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

        # load type files
        Dir[File.join(File.dirname(__FILE__),'types','*.rb')].each do |type_file|
          load(type_file)
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