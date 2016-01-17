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
        # This is always going to add just another constraint to the var that will
        # be resolved in the unification process.
        # No need to check the compatible value.
        lvalue_type.compatible?(rvalue_type, :gt)
        rvalue_type
      end
    end
  end
end
