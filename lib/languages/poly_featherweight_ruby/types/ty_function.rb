module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Types
        class TyFunction < Type
          attr_accessor :from, :to, :parameters_info, :local_typing_context

          def initialize(from, to, parameters_info = nil)
            @from            = from.is_a?(Array) ? from : [from]
            @to              = to
            @parameters_info = parameters_info
            @applicaton_count = 0
          end

          def to_s
            "(#{@from.map(&:to_s).join(',')} -> #{@to})"
          end

          def materialize
            fail StandardError, 'Cannot materialize function because of missing local typing context' if @local_typing_context.nil?
            materialized_from_args = []
            materialized_to_arg = nil

            @applicaton_count += 1
            substitutions = @local_typing_context.local_var_types.each_with_object({}) do |var_type, acc|
              acc[var_type] = Polymorphism::TypeVariable.new("#{var_type}_#{@applicaton_count}")
              maybe_from_arg_index = from.index(var_type)
              if maybe_from_arg_index
                materialized_from_args[maybe_from_arg_index] = acc[var_type]
              end
              if to == var_type
                materialized_to_arg = var_type
              end
            end

            if materialized_from_args.size != from.size
              fail StandardError, "Cannot find all the type variables for function application in the local typing context, expected #{from.size} got #{materialized_from_args.size}."
            end

            if materialized_to_arg.nil?
              fail StandardError, "Cannot find the return type variable for function application in the local typing context."
            end
            applied_typing_context = @local_typing_context.apply_type(@local_typing_context.parent, substitutions)
            TypingContext.with_context(applied_typing_context) do
              yield materialized_from_args
            end
            # got all the constraints here
            # do something with the context -> unification? merge context?

            TyFunction.new(materialized_from_args, materialized_to_arg, parameters_info, @local_typing_context)
          end
        end
      end
    end
  end
end
