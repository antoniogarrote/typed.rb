module TypedRb
  module Languages
    module FeatherweightRuby
      module Types

        class TyFunction < Type
          attr_accessor :from, :to

          def initialize(from, to)
            @from = from
            @to = to
          end

          def to_s
            "(#{@from.map(&:to_s).join(',')} -> #{@to})"
          end

          def can_apply?(arg_types)

          end
        end
      end
    end
  end
end

