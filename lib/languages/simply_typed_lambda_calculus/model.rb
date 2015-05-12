# -*- coding: utf-8 -*-
module TypedRb
  module Languages
    module SimplyTypedLambdaCalculus
      module Model

        class TypeError < StandardError

          attr_reader :term

          def initialize(msg,term)
            super(msg)
            @term = term
          end
        end

        class Expr
          attr_reader :line, :col, :type

          def initialize(node,type = nil)
            @line = node.location.line
            @col = node.location.column
            @type = type
          end

          def shift(displacement, accum_num_binders)
            self
          end

          def substitute(from,to)
            self
          end

          def eval
            self
          end

          def check_type(context)
            fail RuntimeError, "Unknown type" if @type.nil?
            @type
          end
        end

        # integers
        class TmInt < Expr

          attr_accessor :val

          def initialize(node)
            super(node,TyInteger.new)
            @val = node.children.first
          end

          def to_s
            "#{@val}"
          end
        end

        # booleans
        class TmBoolean < Expr

          attr_accessor :val

          def initialize(node)
            super(node, TyBoolean.new)
            @val = node.type == "true" ? true : false
          end

          def to_s
            if @val
              "True"
            else
              "False"
            end
          end
        end

        class TmIfElse < Expr
          def initialize(node, condition_expr, then_expr, else_expr)
            super(node, nil)
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

          def shift(displacement, accum_num_binders)
            @condition_expr.shift(displacement,accum_num_binders)
            @then_expr.shift(displacement,accum_num_binders)
            @else_expr.shift(displacement,accum_num_binders)
            self
          end

          def substitute(from,to)
            @condition_expr.substitute(from,to)
            @then_expr.substitute(from,to)
            @else_expr.substitute(from,to)
            self
          end

          def check_type(context)
            if condition_expr.check_type(context).compatible?(TmBoolean)
              then_expr_type = then_expr_type.check_type(context)
              else_expr_type = else_expr.check_type(context)
              if then_expr_type.compatible?(else_expr_type)
                else_expr_type
              else
              fail TypeError, "Arms of conditional have different types", self
              end
            else
              fail TypeError, "Expected Bool type in if conditional expression", condition_expr
            end
          end
        end

        # variable
        class TmVar < Expr

          attr_accessor :index, :val

          def initialize(val,node)
            super(node)
            @val = val
            @index = nil
          end

          def shift(displacement, accum_num_binders)
            if @index >= accum_num_binders
              @index += displacement
            end
            self
          end

          def substitute(from,to)
            #put "TERM SUBS(#{@index}) #{from} -> #{to}"
            if @index == from
              to
            else
              self
            end
          end

          def to_s(label = true)
            "#{label ? @val : @index}"
          end

          def check_type(context)
            fail "Not implemented yet"
            context.get_type_for(@val)
          end
        end

        # abstraction
        class TmAbs < Expr

          attr_accessor :head, :term

          def initialize(head,term,type,node)
            super(node, type)
            raise StandardError, "Missing type annotation for abstraction" if type.nil?
            @head = head
            @term = term
          end

          def shift(displacement, accum_num_binders)
            @term = @term.shift(displacement, accum_num_binders + 1)
            self
          end

          def substitute(from,to)
            #put "APP SUBSTITUTING [#{from} -> #{to}]"
            @term = @term.substitute(from + 1, to.shift(1,0))
            self
          end

          def eval
            #puts "ABS"
            #puts self.to_s
            @term = @term.eval
            self
          end

          def to_s(label = true)
            if label
              "λ#{@head}:#{type}.#{@term}"
            else
              "λ:#{type}.#{@term.to_s(false)}"
            end
          end

          def check_type(context)
            fail "Not implemented yet"
          end
        end

        # application
        class TmApp < Expr

          attr_accessor :abs,:subs

          def initialize(abs,subs,node)
            super(node)
            @abs = abs
            @subs = subs
          end

          def shift(displacement, accum_num_binders)
            @abs = @abs.shift(displacement, accum_num_binders)
            @subs = @subs.shift(displacement, accum_num_binders)
            self
          end

          def substitute(from,to)
            @abs = @abs.substitute(from,to)
            @subs = @subs.substitute(from,to)
            self
          end

          def eval
            #puts "APP"
            #puts self.to_s
            reduced_subs = @subs.eval
            if @abs.class == TmAbs
              @abs = @abs.term.substitute(0, reduced_subs).shift(-1,0)
              @abs.eval
            else
              @abs = @abs.eval
              @subs = reduced_subs
              self
            end
          end

          def to_s(label = true)
            "(#{@abs.to_s(label)} #{@subs.to_s(label)})"
          end

          def check_type(context)
            fail "Not implemented yet"
          end
        end
      end
    end
  end
end
