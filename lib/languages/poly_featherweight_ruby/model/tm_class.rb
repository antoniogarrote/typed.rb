# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Model
        class TmClass < Expr

          attr_reader :class_name, :super_class_name, :body

          def initialize(class_name,super_class_name, body, node)
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
            class_type = TypedRb::Languages::PolyFeatherweightRuby::Types::Type.parse_singleton_object_type(class_name)
            context = context.add_binding(:self, class_type)
            body.check_type(context)
            class_type
          end
        end

      end
    end
  end
end
