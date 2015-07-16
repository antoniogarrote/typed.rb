# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    class TmLet < Expr
      attr_accessor :binding, :term
      def initialize(binding, term, node)
        super(node)
        @binding = binding
        @term = term
      end

      def rename(from_binding, to_binding)
        # let binding shadows variables in the closure
        if @binding == from_binding
          @binding = from_binding
        end
        @term.rename(from_binding, to_binding)
        self
      end

      def check_type(context)
        binding_type = @term.check_type(context)
        context.add_binding!(@binding,binding_type)
      end
    end
  end
end
