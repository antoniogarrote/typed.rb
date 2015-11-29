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
        jump_return, regular_return = nil

        @terms.each do |term|
          type = term.check_type(context)
          if type.stack_jump?
            jump_return = type if jump_return.nil?
          else
            regular_return = type
          end
        end

        jump_return || regular_return
      end
    end
  end
end
