module TypedRb
  module Types
    class TyEither < TyObject
      attr_accessor :options
      def initialize(node=nil)
        super(NilClass, node)
        @options = {}
      end

      def either?
        true
      end

      def return?
        !options[:return].nil? && options[:return].return?
      end

      def break?
        !options[:break].nil? && options[:break].break?
      end

      def next?
        !options[:next].nil? && options[:next].next?
      end

      def has_jump?
        !(options[:return] || options[:next] || options[:break]).nil?
      end

      def kinds
        [:return, :next, :break]
      end

      def [](kind)
        valid_kind?(kind)
        options[kind]
      end

      def []=(kind, value)
        valid_kind?(kind)
        options[kind] = value
      end

      # This compatible function is to use the normal wrapped type in regular comparisons
      def compatible?(other_type, relation = :lt)
        (options[:normal] || TyUnit.new(node)).compatible?(other_type, relation)
      end

      # This compatible function is to build the comparison in conditinal terms
      def compatible_either?(other_type)
        if other_type.either? # either vs either
          kinds.each do |kind|
            check_jump_kind(kind, other_type[kind])
          end
          check_normal_kind(other_type)
        elsif other_type.stack_jump? # either vs jump
          check_jump_kind(other_type.jump_kind, other_type)
        else # either vs normal flow
          check_normal_kind(other_type)
        end
      end

      private

      def check_jump_kind(kind, other_type)
        if self[kind].nil? && other_type
          self[kind] = other_type
        elsif self[kind] && other_type
          max_type = max(self[kind].wrapped_type, other_type.wrapped_type)
          self[kind] = TyStackJump.new(kind, max_type)
        end
      end

      def check_normal_kind(other_type)
        self[:normal] = max(self[:normal], other_type)
      end

      def max(type_a, type_b)
        return (type_a || type_b) if type_a.nil? || type_b.nil?
        return type_b if type_a.is_a?(Types::TyDynamic) || type_a.is_a?(Types::TyDynamicFunction)
        return type_a if type_b.is_a?(Types::TyDynamic) || type_b.is_a?(Types::TyDynamicFunction)
        return type_b if type_a.is_a?(Types::TyError)
        return type_a if type_b.is_a?(Types::TyError)

        type_vars = [type_a, type_b].select { |type| type.is_a?(Polymorphism::TypeVariable) }
        if type_vars.count == 2
          type_vars[0].compatible?(type_vars[1], :lt)
          type_vars[1].compatible?(type_vars[0], :lt)
          type_vars[0]
        elsif type_vars.count == 1
          type_var = type_vars.first
          non_type_var = ([type_a, type_b] - type_vars).first
          type_var.compatible?(non_type_var, :gt)
          type_var
        else
          [type_a, type_b].max rescue type_a.union(type_b)
        end
      end

      def valid_kind?(kind)
        unless kind == :normal || kinds.include?(kind)
          fail Exception, "Invalid kind of either type #{kind}"
        end
      end
    end
  end
end