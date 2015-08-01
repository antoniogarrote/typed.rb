require_relative '../model'

module TypedRb
  module Model
    class TmMassAsgn < Expr
      attr_reader :lhs, :rhs

      def initialize(lhs, rhs,node)
        super(node)
        @lhs = lhs
        @rhs = rhs
      end

      def rename(from_binding, to_binding)
        @lhs = lhs.map { |node| node.renam(from_binding, to_binding) }
        @rhs = rhs.renam(from_binding, to_binding)
        self
      end

      def check_type(context)
        rhs_type = rhs.check_type(context)
        if (rhs_type.ruby_type == Array)
          lhs.each do |node|
            local_asgn = TmLocalVarAsgn.new(node.children.first,
                                            rhs_type.type_vars.first,
                                            node)
            local_asgn.check_type(context)
          end
        else
          local_asgn = TmLocalVarAsgn.new(lhs.first.children.first,
                                          rhs_type,
                                          lhs.first)
          local_asgn.check_type(context)
          lhs.drop(1).each do |node|
            local_asgn = TmLocalVarAsgn.new(node.children.first,
                                            Types::TyUnit.new,
                                            node)
            local_asgn.check_type(context)
          end
        end
        rhs_type
      end
    end
  end
end
