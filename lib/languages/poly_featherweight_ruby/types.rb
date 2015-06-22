module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Types

        class TypeParsingError < StandardError; end

        class TypingContext

          # work with constraints
          class << self

            def type_variable_for(type, variable, hierarchy)
              type_var = hierarchy.detect do |ruby_type|
                type_variables_register[[type, ruby_type, variable]]
              end

              type_var = if type_var.nil?
                           new_var_name = "#{hierarchy.first}:#{variable}"
                           Polymorphism::TypeVariable.new(new_var_name)
                         else
                           type_variables_register[[type, type_var, variable]]
                         end
              type_variables_register[[type, hierarchy.first, variable]] = type_var
              type_var
            end

            def type_variable_for_message(variable, message)
              new_var_name = "#{variable}:#{message}"
              type_var = type_variables_register[[:return, new_var_name]]
              if type_var.nil?
                type_var = Polymorphism::TypeVariable.new(new_var_name)
                type_variables_register[[:return, new_var_name]] = type_var
              end
              type_var
            end

            def type_variable_for_abstraction(abs_kind, variable, context)
              new_var_name = "#{context.context_name}:#{abs_kind}:#{variable}"
              new_var_name = Model::GenSym.next(new_var_name)
              type_var = type_variables_register[[abs_kind.to_sym, new_var_name]]
              if type_var.nil?
                type_var = Polymorphism::TypeVariable.new(new_var_name)
                type_variables_register[[abs_kind.to_sym, new_var_name]] = type_var
              end
              type_var
            end

            def type_variables_register
              @type_variable_register ||= {}
            end

            def all_constraints
              @type_variable_register.values.reduce([]) do |constraints, type_var|
                constraints + type_var.constraints
              end
            end

            def all_variables
              @type_variable_register.values
            end
          end

          # work with types
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

          def context_name
            "#{@bindings[:self].to_s}"
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
            elsif type == 'Boolean'
              TyBoolean.new
            elsif type.is_a?(Array)
              parse_function_type(type.is_a?(Array) ? type : [type])
            else
              parse_object_type(type)
            end
          end

          # other_type is a meta-type not a ruby type
          def compatible?(other_type, relation = :lt)
            if other_type.instance_of?(Class)
              self.instance_of?(other_type) || other_type == TyError
            else
              relation = (relation == :lt ? :gt : lt)
              other_type.instance_of?(self.class, relation) || other_type.instance_of?(TyError)
            end
          end

          def self.parse_object_type(type)
            begin
              if type == :unit
                TyUnit.new
              else
                ruby_type = Object.const_get(type)
                TyObject.new(ruby_type)
              end
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
            return_type = parse(arg_types.pop)
            TyFunction.new(arg_types.map{ |arg| parse(arg) }, return_type)
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

        class TyUnit < TyObject
          def initialize
            super(NilClass)
          end
        end
      end
    end
  end
end
