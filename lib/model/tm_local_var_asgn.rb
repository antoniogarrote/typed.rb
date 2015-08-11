# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    class TmLocalVarAsgn < Expr
      attr_accessor :lhs, :rhs
      #ts '#initialize / String -> Node -> Node -> unit'
      def initialize(lhs, rhs, node)
        super(node)
        @lhs = lhs
        @rhs = rhs
      end

      #ts '#rename / String -> String -> Expr'
      def rename(from_binding, to_binding)
        # let binding shadows variables in the closure
        if lhs == from_binding
          @lhs = to_binding
        end
        rhs.rename(from_binding, to_binding)
        self
      end

      def check_type(context)
        binding_type = rhs.check_type(context)
        maybe_binding = context.get_type_for(lhs)
        if maybe_binding
          if maybe_binding.compatible?(binding_type, :gt)
            maybe_binding
          else
            fail Types::UncomparableTypes.new(maybe_binding, binding_type, node)
          end
        else
          context.add_binding!(lhs, binding_type)
          binding_type
        end
      end
    end
  end
end
