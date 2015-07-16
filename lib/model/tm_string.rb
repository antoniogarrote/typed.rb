# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # strings
    class TmString < Expr
      attr_accessor :val
      def initialize(node)
        super(node,Types::TyString.new)
        @val = node.children.first
      end
    end
  end
end
