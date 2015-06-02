# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module FeatherweightRuby
      module Model
        # instance variable assignation
        class TmInstanceVarAssignment < Expr

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
            rvalue_type = @rvalue.check_type(context)

            self_type = context.get_type_for(:self)
            lvalue_type = self_type.find_var_type(val)
            fail TypeError.new("Cannot find type for variable #{val}", self) if type.nil?
            if lvalue_type.compatible?(rvalue_type)
              lvalue
            else
              fail TypeError.new('Errror finding compatible instance variable check #{val}', self)
            end
          end
        end
      end
    end
  end
end
