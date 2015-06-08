# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Model
        # strings
        class TmString < Expr
          attr_accessor :val
          def initialize(node)
            super(node,Types::TyString.new)
            @val = node.children.first
          end

          def to_s
            "'#{@val.gsub("'","\\'")}'"
          end
        end
      end
    end
  end
end
