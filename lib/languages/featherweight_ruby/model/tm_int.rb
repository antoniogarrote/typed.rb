# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module FeatherweightRuby
      module Model
        # integers
        class TmInt < Expr
          attr_accessor :val
          def initialize(node)
            super(node,Types::TyInteger.new)
            @val = node.children.first
          end

          def to_s
            "#{@val}"
          end
        end
      end
    end
  end
end