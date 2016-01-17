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
        elsif result_type.either?
          process_either_type(result_type, context)
        else
          result_type
        end
      end

      private

      def process_either_type(either_type, context)
        return_type = either_type[:return]
        final_type = either_type.check_type(context, [:normal, :next, :break])
        if return_type.nil?
          final_type
        else
          new_either_type = Types::TyEither.new(node)
          new_either_type[:return] = return_type
          new_either_type[:normal] = final_type
          new_either_type
        end
      end
    end
  end
end
