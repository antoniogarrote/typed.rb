# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    class TmSequencing < Expr
      attr_accessor :terms
      def initialize(terms, node)
        super(node)
        @terms = terms.reject(&:nil?)
      end

      def check_type(context)
        first_type = @terms.first.check_type(context)
        first_type_acc = if @terms.first.is_a?(TmReturn)
                           [first_type, first_type]
                         elsif first_type.is_a?(TmReturn)
                           first_type_return = first_type.check_type(context)
                           [first_type_return, first_type_return]
                         else
                           [first_type]
                         end
        return_types = @terms.drop(1).reduce(first_type_acc) do |acc, term|
          if term.is_a?(TmReturn)
            acc << term.check_type(context)
          else
            term_type = term.check_type(context)
            next_type = if term_type.is_a?(TmReturn)
                          term_type.check_type(context)
                        else
                          term_type
                        end
            acc.shift
            acc.unshift(next_type)
          end
        end
        if return_types.size > 1
          final_return_type = return_types.max rescue Types::TyObject.new(BasicObject, node)
          TmReturn.new(final_return_type, node)
        else
          return_types.first
        end
      end
    end
  end
end
