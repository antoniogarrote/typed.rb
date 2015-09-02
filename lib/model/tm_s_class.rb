# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # Class expression
    class TmSClass < Expr
      attr_reader :class_name, :super_class_name, :body

      def initialize(class_name, body, node)
        super(node)
        @class_name = class_name
        @body = body
      end

      def rename(from_binding, to_binding)
        body.rename(from_binding, to_binding)
        self
      end

      def check_type(context)
        if class_name != :self
          class_type = Runtime::TypeParser.parse_singleton_object_type(class_name)
          class_type.node = node
          context = context.add_binding(:self, class_type)
        end
        body.check_type(context)
      end
    end
  end
end
