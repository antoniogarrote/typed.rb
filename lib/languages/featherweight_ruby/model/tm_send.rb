# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module FeatherweightRuby
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
            end
            # rename default args
            args.each do |arg|
              if arg.first == :optarg
                arg[2] = arg[2].rename(from_binding, to_binding)
              end
            end
            self
          end

          def check_type(context)
            if receiver == :self || receiver.nil?
              # self.m(args), m(args), m
              self_type = context.get_type_for(:self) # check message in self type -> application
              function_type = self_type.find_function_type(message)
              if function_type.nil?
                if context.get_type_for(message) && args.size == 0
                  # m -> m is local variable
                  context.get_ttype_for(message)
                else
                  error_message = "Error typing message, type information for #{self_type}:#{message} found."
                  fail TypeError.new(error_message, self)
                end
              else
                # function application
                check_application(self_type, function_type)
              end
            else
              # x.m(args)
              receiver_type = receiver.check_type(context)
              function_type = receiver_type.find_function_type(message)
              if function_type.nil?
                error_message = "Error typing message, type information for #{receiver_type}:#{message} found."
                fail TypeError.new(error_message, self)
              else
                # function application
                check_application(receiver_type, function_type)
              end
            end

=begin
            context = context.add_binding(head,type.from)
            type_term = term.check_type(context)
            if type.to.nil? || type_term.compatible?(type.to)
              type.to = type_term
              type
            else
              error_message = "Error abstraction type, exepcted #{type} got #{type.from} -> #{type_term}"
              fail TypeError.new(error_message, self)
            end
=end
          end

          def check_application(receiver_type, function_type)

          end
        end
      end
    end
  end
end
