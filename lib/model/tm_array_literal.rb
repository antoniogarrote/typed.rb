require_relative '../model'

module TypedRb
  module Model
    class TmArrayLiteral < Expr
      attr_reader :elements
      def initialize(elements, node)
        super(node)
        @elements = elements
      end

      def rename(from_binding, to_binding)
        @elements = elements.map do |element|
          element.rename(from_binding, to_binding)
        end
        self
      end

      def check_type(context)
        element_types = elements.map { |element|  element.check_type(context) }
        max_type = element_types.max rescue Types::TyObject.new(Object)
        type_var = Types::Polymorphism::TypeVariable.new('Array:X', :gen_name => false,
                                                         :upper_bound => max_type,
                                                         :lower_bound => max_type)
        type_var.bind(max_type)
        Types::TyGenericObject.new(Array, [type_var])
      end
    end
  end
end
