require_relative 'ty_object'

module TypedRb
  module Languages
    module FeatherweightRuby
      module Types
        class TyBoolean < TyObject

          def initialize
            super(TrueClass)
          end

          def to_s
            'Boolean'
          end
        end
      end
    end
  end
end