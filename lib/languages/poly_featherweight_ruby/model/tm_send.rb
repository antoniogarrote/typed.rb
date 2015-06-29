# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Model
        # message send
        class TmSend < Expr
          attr_accessor :receiver, :message, :args
          def initialize(receiver, message, args, node)
            super(node)
            @receiver = receiver
            @message = message
            @args = args
          end

          def to_s
            if args.size == 0
              "[#{receiver} <- #{message}"
            else
              "[#{receiver} <- #{message}(#{args.map(&to_s).join(',')})"
            end
          end

          def rename(from_binding, to_binding)
            # rename receiver
            if !@receiver.nil? && @receiver != :self
              @receiver = @receiver.rename(from_binding, to_binding)
            elsif @receiver.nil? && @message == from_binding.to_sym
              @message = to_binding.to_sym
            end

            # rename default args
            @args = @args.map { |arg| arg.rename(from_binding, to_binding) }
            self
          end

          def check_type(context)
            if receiver.nil? && message.to_s == 'ts'
              # ignore, => type annotation
            elsif message == :new && !singleton_object_type(receiver, context).nil?
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
            receiver_type = if (receiver.nil? || receiver == :self)
                              context.get_type_for(:self)
                            else
                              receiver.check_type(context)
                            end
            if receiver_type.instance_of?(TypedRb::Languages::PolyFeatherweightRuby::Types::TySingletonObject)
              receiver_type
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
            function_type = self_type.find_function_type(:initialize)
            if function_type.nil?
              error_message = "Error typing message, type information for #{receiver_type} constructor found."
              fail TypeError.new(error_message, self)
            else
              # function application
              @message = :initialize
              check_application(self_type, function_type, context)
              self_type
            end
          end

          def check_type_no_explicit_receiver(context)
            # local variables take precedence over message sending
            if context.get_type_for(message) && args.size == 0
              context.get_type_for(message)
            else
              self_type = context.get_type_for(:self) # check message in self type -> application
              function_type = self_type.find_function_type(message)
              if function_type.nil?
                error_message = "Error typing message, type information for #{self_type}:#{message} found."
                fail TypeError.new(error_message, self)
              else
              # function application
                check_application(self_type, function_type, context)
              end
            end
          end

          def check_type_explicit_receiver(context)
            receiver_type = receiver.check_type(context)
            if receiver_type.is_a?(Types::Polymorphism::TypeVariable)
              arg_types = args.map { |arg| arg.check_type(context) }
              receiver_type.add_message_constraint(message, arg_types)
            elsif receiver_type.is_a?(Types::TyFunction) && (message == :[] || message == :call)
              check_lambda_application(receiver_type, context)
            else
              function_type = receiver_type.find_function_type(message)
              if function_type.nil?
                error_message = "Error typing message, type information for #{receiver_type}:#{message} found."
                fail TypeError.new(error_message, self)
              else
                # function application
                check_application(receiver_type, function_type, context)
              end
            end
          end

          def check_application(receiver_type, function_type, context)
            formal_parameters = function_type.from
            method = receiver_type.resolve_ruby_method(message)
            parameters_info = method.parameters
            check_args_application(parameters_info, formal_parameters, args, context)
            function_type.to
          end

          def check_lambda_application(lambda_type, context)
            parameters_info = lambda_type.parameters_info
            formal_parameters = lambda_type.from
            check_args_application(parameters_info, formal_parameters, args, context)
            lambda_type.to
          end

          def check_args_application(parameters_info, formal_parameters, actual_arguments, context)
            parameters_info.each_with_index do |(require_info, arg_name), index|
              actual_argument = actual_arguments[index]
              formal_parameter_type = formal_parameters[index]
              if actual_argument.nil? && require_info != :opt
                fail TypeError.new("Missing mandatory argument #{arg_name} in #{receiver_type}##{message}", self)
              else
                unless actual_argument.nil? # opt if this is nil
                  actual_argument_type = actual_argument.check_type(context)
                  unless actual_argument_type.compatible?(formal_parameter_type)
                    error_message = "#{error_message} #{formal_parameter_type} expected, #{argument_type} found"
                    fail TypeError.new(error_message, self)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
