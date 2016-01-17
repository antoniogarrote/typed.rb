# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # Class expression
    class TmClass < Expr
      attr_reader :class_name, :super_class_name, :body

      def initialize(class_name, super_class_name, body, node)
        super(node)
        @class_name = class_name
        @super_class_name = super_class_name
        @body = body
      end

      def check_type(context)
        class_ruby_type = Types::TypingContext.find_namespace(class_name)
        class_type = Runtime::TypeParser.parse_singleton_object_type(class_ruby_type.name)
        context = context.add_binding(:self, class_type)
        Types::TypingContext.namespace_push(class_name)
        result_type = if class_type.is_a?(Types::TyGenericSingletonObject)
                        # If the type is generic, we will collect all the restrictions
                        # found while processing the class body in a local type_context.
                        # This context will be complemented with the remaining restrictions
                        # coming from type var application when the generic type becomes
                        # concrete to yield the final type.
                        TmClass.with_fresh_bindings(class_type, context, node) do
                          body.check_type(context) if body
                        end
                      else
                        body.check_type(context) if body
                      end
        Types::TypingContext.namespace_pop
        result_type || Types::TyUnit.new(node)
      end

      def self.with_fresh_bindings(generic_class, _context, node)
        Types::TypingContext.push_context(:class)
        # Deal with upper/lower bounds here if required
        generic_class.type_vars.each do |type_var|
          type_var = Types::TypingContext.type_variable_for_generic_type(type_var)
          type_var.node = node

          if type_var.upper_bound
            type_var.compatible?(type_var.upper_bound, :lt)
          end

          if type_var.lower_bound
            type_var.compatible?(type_var.lower_bound, :gt)
          end
        end
        body_return_type  = yield if block_given?
        # Since every single time we find the generic type the same instance
        # will be returned, the local_typing_context will still be associated.
        # This is the reason we need to build a new typing context cloning this
        # one while type materialization.
        generic_class.local_typing_context = Types::TypingContext.pop_context
        body_return_type
      end
    end
  end
end
