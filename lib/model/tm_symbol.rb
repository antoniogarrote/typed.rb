# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # floats
    class TmSymbol < Expr
      attr_accessor :val
      def initialize(node)
        super(node,Types::TySymbol.new)
        @val = node.children.first
      end

      def to_s
        "#{@val}"
      end
    end
  end
end
