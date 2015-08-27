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
        "\n  #{msg}\n...\n#NO FILE:#{nodes.first.loc.line}\n#{'=' * (nodes.first.loc.column - 2)}> #{nodes.first.loc.expression.source}\n\
#NO FILE:#{nodes.last.loc.line}\n#{'=' * (nodes.last.loc.column - 2)}> #{nodes.last.loc.expression.source}\n...\n"
      elsif nodes
        line = nodes.loc.line
        "\n#NO FILE:#{line}\n  #{msg}\n...\n#{'=' * (nodes.loc.column - 2)}> #{nodes.loc.expression.source}\n...\n"
      else
        msg
      end
    end
  end

  module Types

    class TypeParsingError < TypeCheckError; end

    class TypingContext

      class << self

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

      # This is only used from the runtime parsing logic
      # TODO: move it to Runtime?
      def self.parse(type, klass)
        fail TypeParsingError, 'Error parsing type: nil value.' if type.nil?
        if type == 'unit'
          TyUnit.new
        elsif type == 'Boolean'
          TyBoolean.new
        elsif type.is_a?(Array)
          parse_function_type(type, klass)
        elsif type.is_a?(Hash) && (type[:kind]  == :type_var || type[:kind] == :method_type_var)
          type[:type] = "#{klass}:#{type[:type]}"
          parse_type_var(type)
        elsif type.is_a?(Hash) && type[:kind]  == :generic_type
          parse_concrete_type(type, klass)
        elsif type.is_a?(Hash) && type[:kind]  == :rest
          parse_rest_args(type,klass)
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

      def self.parse_type_var(type)
        if type[:binding] == '<'
          Polymorphism::TypeVariable.new(type[:type],
                                         :upper_bound => TySingletonObject.new(Object.const_get(type[:bound])),
                                         :gen_name    => false)
        elsif type[:binding] == '>'
          Polymorphism::TypeVariable.new(type[:type],
                                         :lower_bound => TySingletonObject.new(Object.const_get(type[:bound])),
                                         :gen_name    => false)
        else
          Polymorphism::TypeVariable.new(type[:type], :gen_name => false)
        end
      end

      def self.parse_rest_args(type,  klass)
        parsed_parameter = parse(type[:parameters].first, klass)
        if parsed_parameter.is_a?(Polymorphism::TypeVariable)
          #TODO: should I use #parse_singleton_object_type here?
          Types::TyGenericSingletonObject.new(Array, [parsed_parameter])
        else
          type_var = Polymorphism::TypeVariable.new('Array:T', :gen_name => false,
                                                               :upper_bound => parsed_parameter,
                                                               :lower_bound => parsed_parameter)
          type_var.bind(parsed_parameter)
          Types::TyGenericObject.new(Array, [type_var])
        end
      end

      def self.parse_concrete_type(type, klass)
        # parameter_names -> container class type vars
        TypedRb.log(binding, :debug, "Parsing concrete type #{type} within #{klass}")

        parameter_names = BasicObject::TypeRegistry.type_vars_for(klass).each_with_object({}) do |variable, acc|
          acc[variable.name.split(':').last] = variable
        end
        # this is the concrete argument to parse
        # it might refer to type vars in the container class
        ruby_type = Object.const_get(type[:type])
        is_generic = false
        concrete_type_vars = []
        # for each parameter:
        # - klass.is_variable? -> variable -> generic singletion
        # - klass.is not variable? ->  bound_type -> generic object
        rrt = BasicObject::TypeRegistry.type_vars_for(ruby_type)
        rrt.each_with_index do |type_var, i|
          param = type[:parameters][i]
          maybe_bound_param = parameter_names[param[:type]]
          parsed_type_var = if maybe_bound_param
                              is_generic = true
                              maybe_bound_param
                            else
                              if param[:kind] == :generic_type
                                # It is a nested generic type
                                klass = Object.const_get(param[:type])
                                bound = parse(param, klass)
                                concrete_param = Types::Polymorphism::TypeVariable.new(type_var.name,
                                                                                       :upper_bound => bound,
                                                                                       :lower_bound => bound,
                                                                                       :gen_name => false)
                                concrete_param.bind(bound)
                                is_generic = bound.is_a?(Types::TyGenericSingletonObject) ? true : false
                                concrete_param
                              elsif param[:bound]
                                # A type parameter that is not bound in the generic type declaration.
                                # It has to be local to the method (TODO: not implemented yet)
                                # or a wildcard '?'
                                is_generic = true
                                # TODO: add some reference to the method if the variable is method specific?
                                if param[:type] == '?'
                                  param[:type] = "#{type_var.name}:#{type_application_counter}:#{param[:type]}"
                                else
                                  param[:type] = "#{type_var.name}:#{param[:type]}:#{type_application_counter}"
                                end
                                parse(param, klass)
                              elsif param[:sub_kind] == :method_type_var
                                # A type parameter that is not bound in the generic type declaration.
                                # It has to be local to the method
                                is_generic = true
                                Types::Polymorphism::TypeVariable.new("#{klass}:#{param[:type]}", :gen_name => false)
                              else
                                begin
                                # The Generic type is bound to a concrete type: bound == upper_bound == lower_bound
                                bound = TySingletonObject.new(Object.const_get(param[:type]))
                                concrete_param = Types::Polymorphism::TypeVariable.new(type_var.name,
                                                                                       :upper_bound => bound,
                                                                                       :lower_bound => bound,
                                                                                       :gen_name => false)
                                concrete_param.bind(bound)
                                concrete_param
                                rescue NameError => e
                                  # TODO: transform this into the method_type_var shown before
                                  is_generic = true
                                  Types::Polymorphism::TypeVariable.new(param[:type], :gen_name => false)
                                end
                              end
                            end
          concrete_type_vars << parsed_type_var
        end

        if is_generic
          Types::TyGenericSingletonObject.new(ruby_type, concrete_type_vars)
        else
          Types::TyGenericObject.new(ruby_type, concrete_type_vars)
        end
      end

      def self.type_application_counter
        @type_application_counter ||= 0
        @type_application_counter += 1
      end

      def self.parse_object_type(type)
        if type == :unit
          TyUnit.new
        else
          ruby_type = Object.const_get(type)
          TyObject.new(ruby_type)
        end
      rescue StandardError => e
        TypedRb.log(binding, :error, "Error parsing object from type #{type}, #{e.message}")
        fail TypeParsingError, "Unknown Ruby type #{type}"
      end

      def self.parse_existential_object_type(type)
        ruby_type = Object.const_get(type)
        BasicObject::TypeRegistry.find_existential_type(ruby_type)
      rescue StandardError => e
        TypedRb.log(binding, :error, "Error parsing existential object from type #{type}, #{e.message}")
        raise TypeParsingError, "Unknown Ruby type #{type}"
      end

      def self.parse_singleton_object_type(type, node=nil)
        ruby_type = Object.const_get(type)
        generic_type = BasicObject::TypeRegistry.find_generic_type(ruby_type)
        if generic_type
          generic_type.node = node
          generic_type
        else
          TySingletonObject.new(ruby_type, node)
        end
      rescue StandardError => e
        TypedRb.log(binding, :error, "Error parsing singleton object from type #{type}, #{e.message}")
        raise TypeParsingError, "Unknown Ruby type #{type}"
      end

      def self.parse_function_type(arg_types, klass)
        return_type = parse(arg_types.pop, klass)
        block_type = if arg_types.last.is_a?(Hash) && arg_types.last[:kind] == :block_arg
                       block_type = arg_types.pop
                       parse_function_type(block_type[:block], klass)
                     else
                       nil
                     end
        arg_types = arg_types.map{ |arg| parse(arg, klass) }
        is_generic = (arg_types + [return_type]).any? { |var| var.is_a?(Types::TyGenericSingletonObject) ||
                                                              var.is_a?(Types::Polymorphism::TypeVariable) }

        is_generic = is_generic || block_type.generic? if block_type

        function_class = is_generic ? TyGenericFunction : TyFunction
        function_type = function_class.new(arg_types, return_type)
        function_type.local_typing_context = TypingContext.empty_typing_context if function_type.generic?
        function_type.with_block_type(block_type) if block_type
        function_type
      end
    end

    # load type files
    Dir[File.join(File.dirname(__FILE__),'types','*.rb')].each do |type_file|
      load(type_file)
    end

    # Aliases for different basic types

    class TyInteger < TyObject
      def initialize(node = nil)
        super(Integer, node)
      end
    end

    class TyFloat < TyObject
      def initialize(node = nil)
        super(Float, node)
      end
    end

    class TyString < TyObject
      def initialize(node = nil)
        super(String, node)
      end
    end

    class TyUnit < TyObject
      def initialize(node = nil)
        super(NilClass, node)
      end
    end

    class TySymbol < TyObject
      def initialize(node = nil)
        super(Symbol, node)
      end
    end

    class TyRegexp < TyObject
      def initialize(node = nil)
        super(Regexp, node)
      end
    end
  end
end
