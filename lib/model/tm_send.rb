# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # message send
    class TmSend < Expr
      attr_accessor :receiver, :message, :args, :block
      def initialize(receiver, message, args, node)
        super(node)
        @receiver = receiver
        @message = message
        @args = args
        @block = nil
      end

      def with_block(block)
        @block = block
      end

      def check_type(context)
        @context = context
        TypedRb.log(binding, :debug,  "Type checking message sent: #{message} at line #{node.loc.line}")
        if receiver.nil? && message == :ts
          # ignore, => type annotation
        elsif message == :new && !singleton_object_type(receiver, context).nil? # clean this!
          check_instantiation(context)
        elsif receiver == :self || receiver.nil?
          # self.m(args), m(args), m
          check_type_no_explicit_receiver(context)
        else
          # x.m(args)
          check_type_explicit_receiver(context)
        end
      end

      def singleton_object_type(receiver,context)
        parsed_receiver_type = if (receiver.nil? || receiver == :self)
                                 context.get_type_for(:self)
                               else
                                 receiver_type
                               end
        if parsed_receiver_type.is_a?(Types::TySingletonObject)
          parsed_receiver_type
        else
          nil
        end
      end

      # we received new, but we look for initialize in the class,
      # not the singleton class.
      # we then run the regular application,
      # but we return the class type instead of the return type
      # for the constructor application (should be unit/nil).
      def check_instantiation(context)
        self_type = singleton_object_type(receiver,context).as_object_type
        function_klass_type, function_type = self_type.find_function_type(:initialize, args.size, @block)
        if function_type.nil?
          error_message = "Error type checking message sent '#{message}': Type information for #{receiver_type} constructor not found"
          fail TypeCheckError.new(error_message, node)
        else
          # function application
          @message = :initialize
          begin
            check_application(self_type, function_type, context)
          rescue TypeCheckError => error
            raise error if function_klass_type == self_type.ruby_type
          end
          self_type
        end
      end

      def check_type_no_explicit_receiver(context)
        # local variables take precedence over message sending
        if context.get_type_for(message) && args.size == 0
          context.get_type_for(message)
        elsif message == :yield
          yield_abs_type = context.get_type_for(:yield)
          if yield_abs_type
            check_lambda_application(yield_abs_type, context)
          else
            fail TypeCheckError.new("Error type checking message sent '#{message}': Cannot find yield function defined in typing context", node)
          end
        else
          self_type = context.get_type_for(:self) # check message in self type -> application
          if self_type.is_a?(Types::Polymorphism::TypeVariable) # Existential type (Module)
            # TODO: what can we do if this is the inclusion of a module?
            arg_types = args.map { |arg| arg.check_type(context) }
            self_type.add_message_constraint(message, arg_types)
          else
            function_klass_type, function_type = self_type.find_function_type(message, args.size, @block)
            begin
              if function_type.nil?
                error_message = "Error type checking message sent '#{message}': Type information for #{self_type}:#{message} not found"
                fail TypeCheckError.new(error_message, node)
              elsif cast?(function_klass_type)
                check_casting(context)
              elsif module_include_implementation?(function_klass_type)
                check_module_inclusions(self_type, context)
              else
                # function application
                check_application(self_type, function_type, context)
              end
            rescue TypeCheckError => error
              if  !(function_klass_type == :main && self_type.is_a?(Types::TyTopLevelObject)) && function_klass_type != self_type.ruby_type
                Types::TyDynamic.new(Object, node)
              elsif function_klass_type == :main && self_type.is_a?(Types::TyTopLevelObject) && function_type.nil?
                Types::TyDynamic.new(Object, node)
              else
                raise error
              end
            end
          end
        end
      end

      def check_type_explicit_receiver(context)
        if receiver_type.is_a?(Types::Polymorphism::TypeVariable)
          arg_types = args.map { |arg| arg.check_type(context) }
          receiver_type.add_message_constraint(message, arg_types)
        elsif receiver_type.is_a?(Types::TyGenericSingletonObject) && (message == :call)
          # Application of types accept a type class or a string with a type description
          arg_types = parse_type_application_arguments(args, context)
          check_type_application_to_generic(receiver_type, arg_types)
        elsif receiver_type.is_a?(Types::TyFunction) && (message == :[] || message == :call)
          check_lambda_application(receiver_type, context)
        else
          function_klass_type, function_type = receiver_type.find_function_type(message, args.size, @block)
          #begin
            if function_type.nil?
              error_message = "Error type checking message sent '#{message}': Type information for #{receiver_type}:#{message} not found."
              fail TypeCheckError.new(error_message, node)
            elsif module_include_implementation?(function_klass_type)
              check_module_inclusions(receiver_type, context)
            else
              # function application
              check_application(receiver_type, function_type, context)
            end
          #rescue TypeCheckError => error
          #  if function_klass_type != receiver_type.ruby_type
          #    Types::TyDynamic.new(Object, node)
          #  else
          #    raise error
          #  end
          #end
        end
      end

      def parse_type_application_arguments(arguments, context)
        arguments.map do |argument|
          if argument.is_a?(Model::TmString)
            type_var_signature = argument.node.children.first
            maybe_generic_method_var = Types::TypingContext.vars_info(:method)[type_var_signature]
            maybe_generic_class_var = Types::TypingContext.vars_info(:class)[type_var_signature]
            if maybe_generic_method_var || maybe_generic_class_var
              maybe_generic_method_var || maybe_generic_class_var
            else
              type = TypeSignature::Parser.parse(type_var_signature)
              # TODO: do this recursively in the case of nested generic type
              # TODO: do we need it at all?
              klass = if type.is_a?(Hash) && type[:kind] == :generic_type
                        Object.const_get(type[:type])
                      else
                        nil
                      end
              Runtime::TypeParser.parse(type, klass)
            end
          else
            argument.check_type(context)
          end
        end
      end

      def type_application_counter
        @type_application_counter ||= 0
        @type_application_counter += 1
      end

      def check_type_application_to_generic(generic_type, args)
        generic_type.materialize(args)
      end

      def check_application(receiver_type, function_type, context)
        if function_type.is_a?(Types::TyDynamicFunction)
          function_type.to
        else
          if function_type.generic?
            function_type.local_typing_context.parent = Marshal::load(Marshal.dump(Types::TypingContext.type_variables_register))
            return_type = function_type.materialize do |materialized_function|
              check_application(receiver_type, materialized_function, context)
            end.to
            return_type.respond_to?(:as_object_type) ? return_type.as_object_type : return_type
          else
            formal_parameters = function_type.from
            parameters_info = function_type.parameters_info
            TypedRb.log(binding, :debug, "Checking function application #{receiver_type}::#{message}( #{parameters_info} )")
            check_args_application(parameters_info, formal_parameters, args, context)
            if @block
              block_type = @block.check_type(context)
              # TODO:
              # Unification is run here
              # Algorithm is failing:
              # G > String,
              # G < E
              # ========
              # G = [String, ?]
              # -----
              # G = [String, E]
              # E = [String, ?]
              block_type.compatible?(function_type.block_type, :lt) if function_type.block_type
            end
            return_type = function_type.to
            return_type.respond_to?(:as_object_type) ? return_type.as_object_type : return_type
          end
        end
      end

      def check_lambda_application(lambda_type, context)
        # TODO: please, refactor this.
        #Types::TyFunction.instance_method(:check_args_application).bind(lambda_type).call(args, context).to
        lambda_type.check_args_application(args, context).to
      end

      def check_args_application(parameters_info, formal_parameters, actual_arguments, context)
        parameters_info.each_with_index do |(require_info, arg_name), index|
          actual_argument = actual_arguments[index]
          formal_parameter_type = formal_parameters[index]
          if formal_parameter_type.nil? && !require_info == :block
            fail TypeCheckError.new("Error type checking message sent '#{message}': Missing information about argument #{arg_name} in #{receiver}##{message}", node)
          end
          if actual_argument.nil? && require_info != :opt && require_info != :rest && require_info != :block
            fail TypeCheckError.new("Error type checking message sent '#{message}': Missing mandatory argument #{arg_name} in #{receiver}##{message}", node)
          else
            if require_info == :rest
              break if actual_argument.nil? # invocation without any of the optional arguments
              rest_type = formal_parameter_type.type_vars.first
              formal_parameter_type = if rest_type.bound
                                        rest_type.bound
                                      else
                                        rest_type
                                      end
              actual_arguments[index..-1].each do |actual_argument|
                unless actual_argument.check_type(context).compatible?(formal_parameter_type, :lt)
                  error_message = "Error type checking message sent '#{message}': #{formal_parameter_type} expected, #{actual_argument_type} found"
                  fail TypeCheckError.new(error_message, node)
                end
              end
              break
            else
              unless actual_argument.nil? # opt or block if this is nil
                actual_argument_type = actual_argument.check_type(context)
                fail TypeCheckError.new("Error type checking message sent '#{message}': Missing type information for argument '#{arg_name}'", node) if formal_parameter_type.nil?
                begin
                  unless actual_argument_type.compatible?(formal_parameter_type, :lt)
                    error_message = "Error type checking message sent '#{message}': #{formal_parameter_type} expected, #{actual_argument_type} found"
                    fail TypeCheckError.new(error_message, node)
                  end
                rescue Types::UncomparableTypes, ArgumentError
                  fail Types::UncomparableTypes.new(actual_argument_type, formal_parameter_type, node)
                end
              end
            end
          end
        end
      end

      def cast?(function_klass_type)
        function_klass_type == BasicObject && message == :cast
      end

      def check_casting(context)
        from = args[0].check_type(context)
        to = parse_type_application_arguments([args[1]], context).first.as_object_type
        TypedRb.log(binding, :info, "Casting #{from} into #{to}")
        to
      end

      def module_include_implementation?(function_klass_type)
        function_klass_type == Module && message == :include
      end

      def check_module_inclusions(self_type, context)
        args.map do |arg|
          arg.check_type(context)
        end.each do |module_type|
          if module_type.is_a?(Types::TyExistentialType)
            module_type.check_inclusion(self_type)
          else
            error_message = "Error type checking message sent '#{message}': Module type expected for inclusion in #{self_type}, #{module_type} found"
            fail TypeCheckError.new(error_message, node)
          end
        end
        self_type
      end

      def receiver_type
        @receiver_type ||= receiver.check_type(@context)
      end
    end
  end
end
