# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # instance variable assignation
    class TmInstanceVarAssignment < Expr

      attr_accessor :lvalue,:rvalue

      def initialize(lvalue, rvalue, node)
        super(node)
        @lvalue = lvalue
        @rvalue = rvalue
      end

      def check_type(context)
        rvalue_type = rvalue.check_type(context)
        self_type = context.get_type_for(:self)
        lvalue_type = self_type.find_var_type(lvalue.val)
        if lvalue_type.nil?
          fail TypeCheckError.new("Error type checking instance variable #{lvalue} assignment: Cannot find type for variable", node)
        end
        if lvalue_type.compatible?(rvalue_type, :gt)
          rvalue_type
        else
          error_message = "Error type checking instance variable #{lvalue} assignment: Error finding compatible instance variable, expected #{lvalue_type} found #{rvalue_type}"
          fail TypeCheckError.new(error_message, node)
        end
      end
    end
  end
end
