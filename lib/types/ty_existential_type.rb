require_relative 'ty_object'

module TypedRb
  module Types
    class TyExistentialType < TyObject

      attr_accessor :local_typing_context, :self_variable

      def initialize(ruby_type)
        super(ruby_type)
      end

      def check_inclusion(self_type)
        Types::TypingContext.with_context(local_typing_context.dup) do
          context_self_type = Types::TypingContext.type_variable_for(ruby_type, :module_self, [ruby_type])
          context_self_type.compatible?(self_type, :lt)

          Types::Polymorphism::Unification.new(Types::TypingContext.all_constraints).run
        end
      end
    end
  end
end
