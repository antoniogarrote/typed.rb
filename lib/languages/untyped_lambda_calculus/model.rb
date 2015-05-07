# -*- coding: utf-8 -*-
module TypedRb
  module Languages
    module UntypedLambdaCalculus
      module Model
        class Expr

          attr_reader :line, :col

          def initialize(node)
            @line = node.location.line
            @col = node.location.column
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

          def eval
            @val
          end

          def to_s(label = true)
            "#{label ? @val : @index}"
          end

        end

        # abstraction
        class TmAbs < Expr

          attr_accessor :head, :term

          def initialize(head,term,node)
            super(node)
            @head = head
            @term = term
          end

          def to_s(label = true)
            if label
              "λ#{@head}.#{@term}"
            else
              "λ.#{@term.to_s(false)}"
            end
          end
        end

        # application
        class TmApp < Expr

          attr_reader :abs,:subs

          def initialize(abs,subs,node)
            super(node)
            @abs = abs
            @subs = subs
          end

          def to_s(label = true)
            "(#{@abs.to_s(label)} #{@subs.to_s(label)})"
          end
        end
      end
    end
  end
end
