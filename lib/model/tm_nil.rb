# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # Nil values
    class TmNil < Expr
      attr_accessor :val
      def initialize(node)
        super(node,Types::TyUnit.new)
      end

      def to_s
        "Nil"
      end
    end
  end
end
