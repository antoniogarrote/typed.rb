require_relative '../model'

module TypedRb
  module Model
    class TmArrayLiteral < Expr
      attr_reader :elements
      def initialize(elements, node)
        super(node)
        @elements = elements
      end

      def check_type(context)
        element_types = elements.map { |element|  element.check_type(context) }
        max_type = element_types.reduce(&:max)
        type_var = Types::Polymorphism::TypeVariable.new('Array:T',
                                                         :node => node,
                                                         :gen_name => false,
                                                         :upper_bound => max_type,
                                                         :lower_bound => max_type)
        type_var.bind(max_type)
        Types::TyGenericObject.new(Array, [type_var], node)
      end
    end
  end
end
