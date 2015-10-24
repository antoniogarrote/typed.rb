# -*- coding: utf-8 -*-
require_relative '../model'
require_relative './tm_instance_var_assignment'

module TypedRb
  module Model
    # global variable assignation
    class TmGlobalVarAssignment < TmInstanceVarAssignment
      def check_type(context)
        rvalue_type = rvalue.check_type(context)
        lvalue_type = Types::TypingContext.type_variable_for_global(lvalue.val)
        if lvalue_type.nil?
          fail TypeCheckError.new("Error type checking global var #{lvalue}: Cannot find type for variable", node)
        end
        if lvalue_type.compatible?(rvalue_type, :gt)
          rvalue_type
        else
          error_message = "Error type checking global var #{lvalue}: Cannot find compatible global variable,  expected #{lvalue_type} found #{rvalue_type}"
          fail TypeCheckError.new(error_message, node)
        end
      end
    end
  end
end
