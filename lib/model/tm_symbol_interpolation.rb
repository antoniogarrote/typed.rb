require_relative '../model'

module TypedRb
  module Model
    # Symbol interpolation
    class TmSymbolInterpolation < Expr
      attr_reader :units
      def initialize(units, node)
        super(node)
        @units = units
      end

      def rename(from_binding, to_binding)
        @units = units.map{ |unit| unit.rename(from_binding, to_binding) }
        self
      end

      def check_type(context)
        units.each do |unit|
          unit.check_type(context)
        end
        Types::TySymbol.new(node)
      end
    end
  end
end
