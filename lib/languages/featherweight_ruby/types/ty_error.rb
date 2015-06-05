module TypedRb
  module Languages
    module FeatherweightRuby
      module Types
        class TyError < Type
          def to_s
            'error'
          end

          def compatible?(_other_type)
            true
          end

          def self.is?(type)
            type == TyError || type.instance_of?(TypeError)
          end
        end
      end
    end
  end
end