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

      def rename(_from_binding, _to_binding)
        # global vars cannot be captured
        self
      end

      def check_type(context)
        Types::TypingContext.type_variable_for_global(val)
      end
    end
  end
end
