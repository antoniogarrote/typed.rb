# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    class TmIfElse < Expr
      attr_reader :condition_expr, :then_expr, :else_expr
      def initialize(node, condition_expr, then_expr, else_expr)
        super(node, nil)
        @condition_expr = condition_expr
        @then_expr = then_expr
        @else_expr = else_expr
      end

      def rename(from_binding, to_binding)
        @condition_expr.rename(from_binding, to_binding)
        @then_expr.rename(from_binding, to_binding)
        @else_expr.rename(from_binding, to_binding) if else_expr
        self
      end

      def check_type(context)
        if @condition_expr.check_type(context).compatible?(Types::TyObject.new(BasicObject, node), :lt)
          then_expr_type = then_expr.nil? ? then_expr : then_expr.check_type(context)
          else_expr_type = else_expr.nil? ? else_expr : else_expr.check_type(context)

          if else_expr_type.nil? || else_expr_type.is_a?(Types::TyUnit)
            if then_expr.is_a?(TmReturn)
              TmReturn.new(then_expr_type, node)
            else
              then_expr_type
            end
          elsif then_expr_type.nil? || then_expr_type.is_a?(Types::TyUnit)
            if else_expr.is_a?(TmReturn)
              TmReturn.new(else_expr_type, node)
            else
              else_expr_type
            end
          else
            if then_expr_type.compatible?(else_expr_type) && else_expr_type.compatible?(then_expr_type)
              result_type = if then_expr_type.is_a?(Types::Polymorphism::TypeVariable)
                              then_expr_type
                            elsif else_expr_type.is_a?(Types::Polymorphism::TypeVariable)
                              else_expr_type
                            elsif Types::TyError.is?(then_expr_type) && !Types::TyError.is?(else_expr_type)
                              else_expr_type
                            elsif Types::TyError.is?(else_expr_type) && !Types::TyError.is?(then_expr_type)
                              then_expr_type
                            elsif then_expr_type.is_a?(Types::TyDynamic) || then_expr_type.is_a?(Types::TyDynamicFunction)
                              else_expr_type
                            else
                              then_expr_type
                            end
              if else_expr_type.is_a?(TmReturn) && then_expr_type.is_a?(TmReturn)
                TmReturn.new(result_type, node)
              elsif else_expr_type.is_a?(TmReturn) && then_expr_type.is_a?(TmReturn)
                fail TypeCheckError.new('Error type checking if/then/else statement: Return statement in only one branch of a conditional', node)
              else
                result_type
              end
            else
              fail TypeCheckError.new("Error type checking if/then/else statement: Arms of conditional have incompatible types #{then_expr_type} vs #{else_expr_type}", node)
            end
          end
        else
          fail TypeCheckError.new('Error type checking if/then/else statement: Expected valid True/False value type in if conditional expression', node)
        end
      end
    end
  end
end
