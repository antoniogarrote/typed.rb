# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module PolyFeatherweightRuby
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

          def to_s
            "class #{class_name} < #{super_class_name}\n#{body}\nend"
          end

          def rename(from_binding, to_binding)
            body.rename(from_binding, to_binding)
            self
          end

          def check_type(context)
            binding.pry
            class_type = Types::Type.parse_singleton_object_type(class_name)
            context = context.add_binding(:self, class_type)
            if class_type.is_a?(Types::TyGenericSingletonObject)
              with_fresh_bindings(class_type, context) do
                body.check_type(context)
              end
            else
              body.check_type(context)
            end
          end


          def with_fresh_bindings(generic_class, context)
            Types::TypingContext.push_context
            generic_class.type_vars.each do |type_var|
              type_var = Types::TypingContext.type_variable_for_generic_type(type_var)
              if type_var.upper_bound != Object
                type_var.compatible?(type_var.upper_bound, :lt)
              end
            end
            body_return_type  = yield
            generic_class.local_typing_context = Types::TypingContext.pop_context
            body_return_type
          end
        end
      end
    end
  end
end
