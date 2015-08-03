# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # Regular expresssion
    class TmRegexp < Expr
      attr_reader :exp, :options
      def initialize(exp, options, node)
        super(node)
        @exp = exp
        @ptions = options
      end

      def rename(from_binding, to_binding)
        exp.rename(from_binding, to_binding)
        options.rename(from_binding, to_binding) if options
        self
      end

      def check_type(context)
        options.check_type(context) if options
        exp_type = exp.check_type(context)
        if exp_type.compatible?(Types::TyString.new, :lt)
          Types::TyRegexp.new
        else
          error_message = "Error typing Regexp, expected String type for expression, found #{exp_type}"
          fail Types::TypeCheckError, error_message
        end
      end
    end
  end
end
