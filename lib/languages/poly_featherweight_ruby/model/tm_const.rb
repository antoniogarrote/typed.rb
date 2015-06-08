require_relative '../model'

module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Model
        class TmConst < Expr

          attr_reader :val

          def initialize(val, node)
            super(node)
            @val = val
          end

          def to_s
            "const #{class_name}"
          end

          def rename(from_binding, to_binding)
            self
          end

          def check_type(context)
            value = Object.const_get(@val)
            if value.instance_of?(Class)
              TypedRb::Languages::PolyFeatherweightRuby::Types::Type.parse_singleton_object_type(value.name)
            else
              TypedRb::Languages::PolyFeatherweightRuby::Types::Type.parse_object_type(value.name)
            end
          end
        end
      end
    end
  end
end
