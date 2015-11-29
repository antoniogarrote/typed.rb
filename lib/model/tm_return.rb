require_relative '../model'

module TypedRb
  module Model
    class TmReturn < Expr
      attr_reader :elements
      def initialize(elements, node)
        super(node)
        @elements = if elements.is_a?(Array)
                      elements
                    else
                      if elements.is_a?(TmReturn)
                        # flattening nested tm_return
                        elments.elements
                      else
                        [elements]
                      end
                    end
      end

      def check_type(context)
        returned_type = if elements.size == 1
                          elements.first.check_type(context)
                        else
                          TmArrayLiteral.new(elements, node).check_type(context)
                        end
        Types::TyStackJump.return(returned_type, node)
      end
    end
  end
end
