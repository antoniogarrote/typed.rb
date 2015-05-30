# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module FeatherweightRuby
      module Model
        # instance variable assignation
        class TmInstanceVarAssignation < Expr

          attr_accessor :lvalue,:rvalue

          def initialize(lvalue, rvalue, node)
            super(node)
            @lvalue = lvalue
            @rvalue = rvalue
          end

          def to_s
            "#{lvalue} = #{rvalue}"
          end

          def rename(from_binding, to_binding)
            @rvalue = @rvalue.rename(from_binding, to_binding)
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
