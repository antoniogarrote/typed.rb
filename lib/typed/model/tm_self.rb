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
          fail TypeCheckError.new.new('Error type checking self reference: Cannot find self reference in typing context', node)
        else
          self_type
        end
      end
    end
  end
end
