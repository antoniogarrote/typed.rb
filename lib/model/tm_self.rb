# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # booleans
    class TmSelf < Expr
      def initialize(node)
        super(node)
      end

      def check_type(context)
        self_type = context.get_type_for(:self)
        if self_type.nil?
          fail TypeCheckError, 'Cannot find self reference in context'
        else
          self_type
        end
      end
    end
  end
end
