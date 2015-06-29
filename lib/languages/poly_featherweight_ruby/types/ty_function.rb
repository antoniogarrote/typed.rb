module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Types

        class TyFunction < Type
          attr_accessor :from, :to, :parameters_info

          def initialize(from, to, parameters_info = nil)
            @from            = from.is_a?(Array) ? from : [from]
            @to              = to
            @parameters_info = parameters_info
          end

          def to_s
            "(#{@from.map(&:to_s).join(',')} -> #{@to})"
          end

          def materialize(from_types = nil, to_type = nil)

          end
        end
      end
    end
  end
end
