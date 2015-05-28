# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module FeatherweightRuby
      module Model
        class TmIfElse < Expr
          def initialize(node, condition_expr, then_expr, else_expr)
            super(node, nil)
            @condition_expr = condition_expr
            @then_expr = then_expr
            @else_expr = else_expr
          end

          def rename(from_binding, to_binding)
            @condition_expr.rename(from_binding, to_binding)
            @then_expr.rename(from_binding, to_binding)
            @else_expr.rename(from_binding, to_binding)
            self
          end

          def check_type(context)
            if @condition_expr.check_type(context).compatible?(Types::TyBoolean)
              then_expr_type = @then_expr.check_type(context)
              else_expr_type = @else_expr.check_type(context)
              if then_expr_type.compatible?(else_expr_type)
                Types::TyError.is?(then_expr_type) ? else_expr_type : then_expr_type
              else
                fail TypeError.new('Arms of conditional have different types', self)
              end
            else
              fail TypeError.new('Expected Bool type in if conditional expression', @condition_expr)
            end
          end

          def to_s
            "if #{@condition_expr} then\n  #{@then_expr}\nelse\n  #{@else_expr}\nend\n"
          end
        end
      end
    end
  end
end