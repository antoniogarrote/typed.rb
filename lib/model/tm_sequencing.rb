# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    class TmSequencing < Expr
      attr_accessor :terms
      def initialize(terms,node)
        super(node)
        @terms = terms.reject(&:nil?)
      end

      def rename(from_binding, to_binding)
        @terms.each{|term| term.rename(from_binding, to_binding) }
        self
      end

      def check_type(context)
        @terms.drop(1).reduce(@terms.first.check_type(context)) {|_,term|
          term.check_type(context)
        }
      end
    end
  end
end
