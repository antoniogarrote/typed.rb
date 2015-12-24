# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    class TmWhile < Expr
      attr_reader :condition_expr, :body_expr
      def initialize(condition_expr, body_expr, node)
        super(node)
        @condition_expr = condition_expr
        @body_expr = body_expr
      end

      def check_type(context)
        condition_expr.check_type(context).compatible?(Types::TyObject.new(BasicObject, node), :lt)
        return Types::TyUnit.new(node) unless body_expr
        while_res = body_expr.check_type(context)
        if while_res.stack_jump? && (while_res.next? || while_res.break?)
          while_res.wrapped_type.check_type(context)
        elsif while_res.either?
          process_either_type(while_res, context)
        else
          while_res
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
