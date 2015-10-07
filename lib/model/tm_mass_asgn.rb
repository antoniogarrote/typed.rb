require_relative '../model'

module TypedRb
  module Model
    class TmMassAsgn < Expr
      attr_reader :lhs, :rhs

      def initialize(lhs, rhs,node)
        super(node)
        @lhs = lhs.map { |lhs_node| lhs_node.children.first }
        @lhs_children = lhs
        @rhs = rhs
      end

      def check_type(context)
        rhs_type = rhs.check_type(context)
        if (rhs_type.ruby_type == Array)
          lhs.each_with_index do |node, i|
            local_asgn = TmLocalVarAsgn.new(node,
                                            rhs_type.type_vars.first,
                                            @lhs_children[i])
            local_asgn.check_type(context)
          end
        else
          local_asgn = TmLocalVarAsgn.new(lhs.first,
                                          rhs_type,
                                          @lhs_children.first)
          local_asgn.check_type(context)
          lhs.drop(1).each_with_index do |node, i|
            local_asgn = TmLocalVarAsgn.new(node,
                                            Types::TyUnit.new,
                                            @lhs_children[i + 1])
            local_asgn.check_type(context)
          end
        end
        rhs_type
      end
    end
  end
end
