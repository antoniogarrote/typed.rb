# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # Nil values
    class TmNil < Expr
      attr_accessor :val
      def initialize(node)
        super(node, Types::TyUnit.new(node))
      end
    end
  end
end
