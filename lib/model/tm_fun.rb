# -*- coding: utf-8 -*-
require_relative '../model'
require_relative 'tm_mlhs'

module TypedRb
  module Model
    # A instance/class function definition expression
    class TmFun < Expr
      attr_accessor :name, :args, :body, :owner
      attr_reader :owner_type

      def initialize(owner, name, args, body, node)
        super(node)
        @owner = parse_owner(owner)
        @name = name
        @args = args
        @body = body
        @arg_count = args.count { |arg| arg.first != :blockarg }
        @has_block = args.detect { |arg| arg.first == :blockarg }
      end

      def check_type(context)
        compute_owner_type(context)

        function_klass_type, function_type = owner_type.find_function_type(name, @arg_count, @has_block)

        # fail TypeCheckError.new("Error type checking function #{owner}##{name}: Cannot find function type information for owner.", node)
        # Missing type information stops the type checking process
        # TODO: raise a warning here about the previous fact
        return Types::TyUnit.new(node) if function_type.nil? || function_type.dynamic?

        context = setup_context(context, function_type)
        # check the body with the new bindings for the args
        TmFun.with_fresh_bindings(function_klass_type, function_type) do
          body_return_type = body.check_type(context)
          TypedRb::Types::TypingContext.function_context_pop
          check_return_type(context, function_type, body_return_type)
        end
      end

      # TODO:
      # 1 Find free type variables for the generic function.
      # 2 Create a new local typing context for the generic function
      # 3 Add free type variables to the typing context
      def self.with_fresh_bindings(klass, function_type)
        if function_type.generic?
          Types::TypingContext.push_context(:method)
          function_type.free_type_variables(klass).each do |type_var|
            # This will add the variable to the context
            Types::TypingContext.type_variable_for_function_type(type_var)
          end

          yield if block_given?

          # # Since every single time we find the generic type the same instance
          # # will be returned, the local_typing_context will still be associated.
          # # This is the reason we need to build a new typing context cloning this
          # # one while type materialization.
          function_type.local_typing_context = Types::TypingContext.pop_context
        else
          yield if block_given?
        end
        function_type
      end

      private

      def parse_owner(owner)
        return nil if owner.nil?
        return :self if owner == :self || owner.type == :self
        # must be a class or other expression we can check the type
        owner
      end

      def compute_owner_type(context)
        @owner_type = if owner == :self
                        context.get_self
                      elsif owner.nil?
                        context.get_self.as_object_type
                      else
                        owner.check_type(context)
                      end
      end

      def process_arguments(context, function_type)
        args.each_with_index do |arg, i|
          function_arg_type = function_type.from[i]
          # Generic arguments are parsed by runtime without checking constraints since they are not available at parsing type.
          # We need to run unification in them before using the type to detect invalid type argument applications.
          function_arg_type = function_arg_type.self_materialize if function_arg_type.is_a?(Types::TyGenericSingletonObject)
          context = case arg.first
                    when :arg, :restarg
                      context.add_binding(arg[1], function_arg_type)
                    when :optarg
                      declared_arg_type = arg.last.check_type(context)
                      context.add_binding(arg[1], function_arg_type) if declared_arg_type.compatible?(function_arg_type)
                    when :blockarg
                      if function_type.block_type
                        context.add_binding(arg[1], function_type.block_type)
                      else
                        fail TypeCheckError.new("Error type checking function #{owner}##{name}: Missing block type for block argument #{arg[1]}", node)
                      end
                    when :mlhs
                      tm_mlhs = arg[1]
                      tm_mlhs.check_type(function_arg_type, context)
                    else
                      fail TypeCheckError.new("Error type checking function #{owner}##{name}: Unknown type of arg #{arg.first}", node)
                    end
        end
        context
      end

      def setup_context(context, function_type)
        context = process_arguments(context, function_type)

        # pointing self to the right type
        self_type = if owner_type.is_a?(Types::TyExistentialType)
                      owner_type.self_variable
                    else
                      owner_type
                    end
        context = context.add_binding(:self, self_type)

        # adding yield binding if present
        context = context.add_binding(:yield, function_type.block_type) if function_type.block_type

        # set the current function context
        TypedRb::Types::TypingContext.function_context_push(self_type, name, function_type.from)

        context
      end

      def check_return_type(context, function_type, body_return_type)
        return function_type.to if function_type.to.instance_of?(Types::TyUnit)
        # Same as before but for the return type
        function_type_to = function_type.to.is_a?(Types::TyGenericSingletonObject) ? function_type.to.clone : function_type.to
        body_return_type = body_return_type.wrapped_type.check_type(context) if body_return_type.stack_jump?
        return function_type if body_return_type.compatible?(function_type_to, :lt)
        # TODO:
        # A TyObject(Symbol) should be returned not the function type
        # x = def id(x); x; end / => x == :id
        error_message = "Error type checking function type #{owner}##{name}: Wrong return type, expected #{function_type.to}, found #{body_return_type}."
        fail TypeCheckError.new(error_message, node)
      end
    end
  end
end
