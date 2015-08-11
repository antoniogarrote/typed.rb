# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # booleans
    class TmBoolean < Expr
      attr_accessor :val
      def initialize(node)
        super(node, Types::TyBoolean.new(node))
        @val = node.type == 'true' ? true : false
      end
    end
  end
end
