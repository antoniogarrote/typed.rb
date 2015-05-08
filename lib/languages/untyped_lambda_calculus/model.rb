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
            puts "VAR"
            puts self.to_s
            self
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

        end

        # abstraction
        class TmAbs < Expr

          attr_accessor :head, :term

          def initialize(head,term,node)
            super(node)
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
            puts "ABS"
            puts self.to_s
            @term = @term.eval
            self
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
            puts "APP"
            puts self.to_s
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
        end
      end
    end
  end
end
