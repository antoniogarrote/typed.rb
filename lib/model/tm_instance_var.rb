# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # instance variable
    class TmInstanceVar < Expr
      attr_accessor :val

      def initialize(val, node)
        super(node)
        @val = val
      end

      def check_type(context)
        self_type = context.get_type_for(:self)
        type = self_type.find_var_type(val)
        fail TypeCheckError.new("Error type checking instance variable #{val}: Cannot find type for variable.", node) if type.nil?
        type
      end
    end
  end
end
