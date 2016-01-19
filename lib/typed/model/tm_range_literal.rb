# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # range literals
    class TmRangeLiteral < Expr
      attr_reader :start_range, :end_range
      def initialize(start_range, end_range, node)
        super(node)
        @start_range = start_range
        @end_range = end_range
      end

      def check_type(context)
        start_range_type = start_range.check_type(context)
        end_range_type = end_range.check_type(context)
        max_type = start_range_type.max(end_range_type)

        type_var = Types::Polymorphism::TypeVariable.new('Range:T',
                                                         :node => node,
                                                         :gen_name => false,
                                                         :upper_bound => max_type,
                                                         :lower_bound => max_type)
        type_var.bind(max_type)
        Types::TyGenericObject.new(Range, [type_var], node)
      end
    end
  end
end
