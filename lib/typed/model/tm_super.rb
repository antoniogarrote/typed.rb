# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # super keyword invocations
    class TmSuper < Expr
      attr_reader :args
      def initialize(args, node)
        super(node)
        @args = args
      end

      def check_type(context)
        if Types::TypingContext.function_context
          self_type, message, args = Types::TypingContext.function_context
          parent_self_type = Types::TyObject.new(self_type.hierarchy.first, node)
          args = @args || args
          args = args.map { |arg| arg.check_type(context) }
          TmSend.new(parent_self_type, message, args, node).check_type(context)
        else
          fail TypeCheckError.new("Error type checking 'super' invocation without function context.", node)
        end
      end
    end
  end
end
