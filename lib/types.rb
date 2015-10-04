module TypedRb

  class TypeCheckError < TypeError
    attr_reader :node

    def initialize(msg, node = nil)
      super(build_message_error(msg, node))
      @node = node
    end

    private

    def build_message_error(msg, nodes)
      if nodes && nodes.is_a?(Array)
        num_columns = (nodes.last.loc.column - 2)
        num_columns = num_columns < 0 ? 0 : num_columns

        "\n  #{msg}\n...\n#NO FILE:#{nodes.first.loc.line}\n#{'=' * (nodes.first.loc.column - 2)}> #{nodes.first.loc.expression.source}\n\
#NO FILE:#{nodes.last.loc.line}\n#{'=' * num_columns}> #{nodes.last.loc.expression.source}\n...\n"
      elsif nodes
        line = nodes.loc.line
        num_columns = (nodes.loc.column - 2)
        num_columns = num_columns < 0 ? 0 : num_columns

        "\n#NO FILE:#{line}\n  #{msg}\n...\n#{'=' * num_columns}> #{nodes.loc.expression.source}\n...\n"
      else
        msg
      end
    end
  end

  module Types

    class TypeParsingError < TypeCheckError; end

    class TypingContext

      class << self

        def namespace
          @namespace ||= []
        end

        def namespace_push(constant)
          parts = constant.split('::')
          @namespace += parts.reject { |part| namespace.include?(part) }
        end

        def namespace_pop
          @namespace.pop
        end

        def find_namespace(constant, namespace = self.namespace)
          return Object.const_get(constant) if constant.start_with?('::')
          Object.const_get(namespace.join('::') + '::' + constant)
        rescue NameError => e
          if namespace.empty?
            raise e
          else
            find_namespace(constant, namespace.take(namespace.size - 1))
          end
        end

        def empty_typing_context
          Polymorphism::TypeVariableRegister.new(nil, :local)
        end

        def type_variables_register
          @type_variables_register ||= Polymorphism::TypeVariableRegister.new(nil, :top_level)
        end

        def type_variable_for(type, variable, hierarchy)
          type_variables_register.type_variable_for(type, variable, hierarchy)
        end

        def type_variable_for_global(variable)
          type_variables_register.type_variable_for_global(variable)
        end

        def type_variable_for_message(variable, message)
          type_variables_register.type_variable_for_message(variable, message)
        end

        def type_variable_for_abstraction(abs_kind, variable, context)
          type_variables_register.type_variable_for_abstraction(abs_kind, variable, context)
        end

        def type_variable_for_function_type(type_var)
          type_variables_register.type_variable_for_generic_type(type_var, true)
        end

        def type_variable_for_generic_type(type_var)
          type_variables_register.type_variable_for_generic_type(type_var)
        end

        def local_type_variable
          type_variables_register.local_type_variable
        end

        def all_constraints
          type_variables_register.all_constraints
        end

        def all_variables
          type_variables_register.all_variables
        end

        def add_constraint(variable, relation, type)
          type_variables_register.add_constraint(variable, relation, type)
        end

        def constraints_for(variable)
          type_variables_register.constraints[variable] || []
        end

        def duplicate(within_context)
          current_parent = type_variables_register.parent
          type_variables_register.parent = nil
          duplicated = Marshal::load(Marshal.dump(within_context))
          type_variables_register.parent = current_parent
          duplicated
        end

        def bound_generic_type_var?(type_variable)
          type_variables_register.bound_generic_type_var?(type_variable)
        end

        def push_context(type)
          new_register = Polymorphism::TypeVariableRegister.new(self.type_variables_register, type)
          @type_variables_register.children << new_register
          @type_variables_register = new_register
          new_register
        end

        def pop_context
          fail StandardError, 'Empty typing context stack, impossible to pop' if @type_variables_register.nil?
          last_register = self.type_variables_register
          @type_variables_register = @type_variables_register.parent
          @type_variables_register.children.reject!{ |child| child == last_register }
          last_register
        end

        def with_context(context)
          old_context = @type_variables_register
          @type_variables_register = context
          result = yield
          @type_variables_register = old_context
          result
        end

        def clear(type)
          @type_variables_register = Polymorphism::TypeVariableRegister.new(type)
        end

        def vars_info(level)
          method_registry = type_variables_register
          while !method_registry.nil? && method_registry.kind != level
            method_registry = method_registry.parent
          end

          if method_registry
            method_registry.type_variables_register.map do |(key, type_var)|
              if key.first == :generic
                type_var
              end
            end.compact.each_with_object({}) do |type_var, acc|
              var_name = type_var.variable.split(':').last
              acc["[#{var_name}]"] = type_var
            end
          else
            {}
          end
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
        type = @bindings[val.to_s]
        if type.nil?
          @parent.get_type_for(val) if @parent
        else
          type
        end
      end

      def get_self
        @bindings['self']
      end

      def context_name
        "#{@bindings['self']}"
      end

      protected

      def push_binding(val,type)
        @bindings[val.to_s] = type
        self
      end
    end

    class Type
      attr_accessor :node

      def initialize(node)
        @node = node
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
    end

    # load type files
    #Dir[File.join(File.dirname(__FILE__),'types','*.rb')].each do |type_file|
    #  load(type_file)
    #end
  end
end
