# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # floats
    class TmFloat < Expr
      attr_accessor :val
      def initialize(node)
        super(node,Types::TyFloat.new)
        @val = node.children.first
      end
    end
  end
end
