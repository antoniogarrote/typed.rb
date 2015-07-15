require_relative '../model'

module TypedRb
  module Model
    # String interpolation
    class TmStringInterpolation < Expr
      attr_reader :units
      def initialize(units, node)
        super(node)
        @units = units
      end

      def to_s
        "String: #{units.map(&:to_s).join(',')}"
      end

      def rename(from_binding, to_binding)
        @units = units.map{ |unit| unit.rename(from_binding, to_binding) }
      end

      def check_type(context)
        units.each do |unit|
          unit.check_type(context)
        end
        Types::TyString.new
      end
    end
  end
end
