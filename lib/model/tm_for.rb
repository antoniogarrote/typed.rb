# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    class TmFor < Expr
      attr_reader :condition, :body
      def initialize(condition, body, node)
        super(node)
        @condition = condition
        @body = body
      end

      def check_type(context)
        condition.check_type(context)
        result_type = body.check_type(context)
        if result_type.stack_jump? && (result_type.next? || result_type.break?)
          result_type.wrapped_type.check_type(context)
        else
          result_type
        end
      end
    end
  end
end
