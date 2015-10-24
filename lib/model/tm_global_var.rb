# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # instance variable
    class TmGlobalVar < Expr
      attr_accessor :val

      def initialize(val, node)
        super(node)
        @val = val
      end

      def check_type(_context)
        type = Types::TypingContext.type_variable_for_global(val)
        type.node = node
        type
      end
    end
  end
end
