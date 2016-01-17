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

      def check_type(context)
        options.check_type(context) if options
        exp_type = exp.check_type(context)
        if exp_type.compatible?(Types::TyString.new(node), :lt)
          Types::TyRegexp.new(node)
        else
          error_message = "Error type checking  Regexp: Expected String type for expression, found #{exp_type}"
          fail Types::TypeCheckError.new(error_message, node)
        end
      end
    end
  end
end
