module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Types

        class TyFunction < Type
          attr_accessor :from, :to

          def initialize(from, to)
            @from = from.is_a?(Array) ?  from : [from]
            @to = to
          end

          def to_s
            "(#{@from.map(&:to_s).join(',')} -> #{@to})"
          end
        end
      end
    end
  end
end
