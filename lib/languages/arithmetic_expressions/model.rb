module TypedRb
  module Languages
    module ArithmeticExpressions
      module Model
        # true value
        class TmTrue
          def eval
            self
          end
        end

        # false value
        class TmFalse
          def eval
            self
          end
        end

        # if then else
        class TmIfElse
          def initialize(condition_expr, then_expr, else_expr)
            @condition_expr = condition_expr
            @then_expr = then_expr
            @else_expr = else_expr
          end

          def eval
            if @condition_expr.eval.instance_of?(TmTrue)
              @then_expr.eval
            else
              @else_expr.eval
            end
          end
        end

        # zero value
        class TmZero
          def eval
            self
          end
        end

        # succ function
        class TmSucc
          def initialize(succ_expr)
            @succ_expr = succ_expr
          end

          def expr
            @succ_expr
          end

          def eval
            TmSucc.new(@succ_expr.eval)
          end
        end

        # pred function
        class TmPred
          def initialize(pred_expr)
            @pred_expr = pred_expr
          end

          def eval
            if @pred_expr.instance_of?(TmZero)
              @pred_expr
            elsif @pred_expr.instance_of?(TmSucc)
              @pred_expr.expr
            else
              TmPred.new(@pred_expr.eval).eval
            end
          end
        end

        # isZero function
        class TmIsZero
          def initialize(is_zero_expr)
            @is_zero_expr = is_zero_expr
          end
          def eval
            if @is_zero_expr.instance_of?(TmZero)
              TmTrue.new
            elsif @is_zero_expr.instance_of?(TmSucc)
              TmFalse.new
            else
              TmIsZero.new(@is_zero_expr.eval).eval
            end
          end
        end
      end
    end
  end
end
