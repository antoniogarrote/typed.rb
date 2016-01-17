# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    class TmIfElse < Expr
      attr_reader :condition_expr, :then_expr
      attr_accessor :else_expr
      def initialize(node, condition_expr, then_expr, else_expr)
        super(node, nil)
        @condition_expr = condition_expr
        @then_expr = then_expr || Types::TyUnit.new
        @else_expr = else_expr || Types::TyUnit.new
      end

      def check_type(context)
        either_type = Types::TyEither.new(node)
        either_type.compatible_either?(then_expr.check_type(context))
        either_type.compatible_either?(else_expr.check_type(context))
        either_type.has_jump? ? either_type : either_type[:normal]
      end
    end
  end
end
