# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module FeatherweightRuby
      module Model
        # instance variable
        class TmInstanceVar < Expr

          attr_accessor :val

          def initialize(val, node)
            super(node)
            @val = val
          end

          def to_s
            "#{val}"
          end

          def rename(from_binding, to_binding)
            # instance vars cannot be captured
            self
          end

          def check_type(context)
            fail "Not implemented yet"
          end
        end
      end
    end
  end
end
