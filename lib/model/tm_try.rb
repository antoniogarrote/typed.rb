# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    class TmTry < Expr
      def initialize(try_term, rescue_terms, node)
        super(node)
        @try_term = try_term
        @rescue_terms = rescue_terms
      end

      def to_s
        "try #{@try_term} #{@rescue_terms.map{|rescue_term| 'with '+(rescue_term||'unit').to_s }.join(' ')}"
      end

      def rename(from_binding, to_binding)
        @try_term.rename(from_binding, to_binding)
        @rescue_terms.each{|term| term.rename(from_binding, to_binding) }
      end

      def check_type(context)
        try_term_type = @try_term.check_type(context)
        rescue_term_types = @rescue_terms.map do |term|
          if term.nil?
            TyUnit.new
          else
            term.check_type(context)
          end
        end
        incompatible_type = rescue_term_types.detect{|term_type| !try_term_type.compatible?(term_type) }
        if incompatible_type
          fail TypeCheckError "Error in rescue clause, expected type #{try_term_type} got #{incompatible_type}"
        else
          try_term_type
        end
      end
    end
  end
end
