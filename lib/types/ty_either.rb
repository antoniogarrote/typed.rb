module TypedRb
  module Types
    class TyEither < TyObject
      attr_accessor :options
      def initialize(node=nil)
        super(NilClass, node)
        @options = { :normal => TypedRb::Types::TyUnit.new }
      end

      def self.wrap(type)
        if type.either?
          type
        elsif type.stack_jump?
          either = TyEither.new(type.node)
          either[type.jump_kind] = type
          either
        else
          either = TyEither.new(type.node)
          either[:normal] = type
          either
        end
      end

      def unwrap
        normal = self[:normal].is_a?(TypedRb::Types::TyUnit) ? nil : self[:normal]
        wrapped_types = [normal, self[:return], self[:break], self[:next]].compact
        if wrapped_types.count > 1
          self
        elsif wrapped_types.count == 1
          wrapped_types.first
        else
          TypedRb::Types::TyUnit.new
        end
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

      def all_kinds
        [:normal] + kinds
      end

      def [](kind)
        valid_kind?(kind)
        options[kind]
      end

      def []=(kind, value)
        valid_kind?(kind)
        options[kind] = value
      end

      def check_type(context, types=[:return])
        relevant_types = types.map { |type| self[type] }.reject(&:nil?)
        relevant_types = relevant_types.map { |type| type.stack_jump? ? type.wrapped_type : type }
        relevant_types = relevant_types.map { |type| type.check_type(context) }
        relevant_types.max rescue relevant_types.reduce { |type_a, type_b| type_a.union(type_b) }
      end

      # This compatible function is to use the normal wrapped type in regular comparisons
      def compatible?(other_type, relation = :lt)
        (options[:normal] || TyUnit.new(node)).compatible?(other_type, relation)
      end

      # This compatible function is to build the comparison in conditional terms
      def compatible_either?(other_type)
        if other_type.either? # either vs either
          kinds.each do |kind|
            check_jump_kind(kind, other_type[kind])
          end
          check_normal_kind(other_type[:normal])
        elsif other_type.stack_jump? # either vs jump
          check_jump_kind(other_type.jump_kind, other_type)
        else # either vs normal flow
          check_normal_kind(other_type)
        end
        self
      end

      def to_s
        vals = options.to_a.reject {|(k,v)| v.nil? }.map{ |k,v| "#{k}:#{v}" }.join(" | ")
        "Either[#{vals}]"
      end

      def apply_bindings(bindings_map)
        all_kinds.each do |kind|
          if self[kind]
            if self[kind].is_a?(Polymorphism::TypeVariable)
              self[kind].apply_bindings(bindings_map)
              self[kind] = self[kind].bound if self[kind].bound
            elsif self[kind].is_a?(TyGenericSingletonObject) || self[kind].is_a?(TyGenericObject)
              self[kind].apply_bindings(bindings_map)
            end
          end
        end
        self
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