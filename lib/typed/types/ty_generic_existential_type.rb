require_relative 'ty_object'
require_relative 'singleton_object'

module TypedRb
  module Types
    class TyGenericExistentialType < TyExistentialType
      include Polymorphism::GenericObject
      include Polymorphism::GenericComparisons
      include Polymorphism::GenericVariables
      include SingletonObject

      attr_accessor :local_typing_context, :self_variable

      def initialize(ruby_type, type_vars, node = nil)
        super(ruby_type, node)
        @type_vars = type_vars
      end

      def check_inclusion(self_type)
        if self_type.generic?
          if ancestor_of_super_type?(self_type.super_type, ruby_type)
            super_type = ancestor_of_super_type?(self_type.super_type, ruby_type)
            materialize(self_type, super_type.type_vars)
          else
            materialize(self_type, self_type.type_vars)
          end
        else
          # not generic extending a generic type
          raise StandardError, "Extending generic module type #{ruby_type} in #{self_type} without matching super annotation"
        end
      end

      def materialize(self_type, actual_arguments)
        TypedRb.log binding, :debug, "Materialising generic existential type '#{self}' with args [#{actual_arguments.map(&:to_s).join(',')}]"
        compute_minimal_typing_context if @local_typing_context.nil?

        applied_typing_context, substitutions = @local_typing_context.clone(:module_self)
        fresh_vars_generic_type = clone_with_substitutions(substitutions)
        TypingContext.with_context(applied_typing_context) do
          apply_type_arguments(fresh_vars_generic_type, actual_arguments)
          context_self_type = Types::TypingContext.type_variable_for(ruby_type, :module_self, [ruby_type])
          context_self_type.compatible?(self_type, :lt)
        end
        Polymorphism::Unification.new(applied_typing_context.all_constraints).run(false)
        applied_typing_context.unlink # these constraints have already been satisfied
      end

      def clean_dynamic_bindings
        type_vars.each do |type_var|
          type_var.clean_dynamic_bindings
        end
        local_typing_context.clean_dynamic_bindings
      end
    end
  end
end
