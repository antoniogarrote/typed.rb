module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Types
        class TyFunction < Type
          attr_accessor :from, :to, :parameters_info

          def initialize(from, to, parameters_info = nil)
            @from            = from.is_a?(Array) ? from : [from]
            @to              = to
            @parameters_info = parameters_info
          end

          def to_s
            "(#{@from.map(&:to_s).join(',')} -> #{@to})"
          end

          def check_args_application(actual_arguments, context)
            parameters_info.each_with_index do |(require_info, arg_name), index|
              actual_argument = actual_arguments[index]
              from_type = from[index]
              if actual_argument.nil? && require_info != :opt
                fail TypeError.new("Missing mandatory argument #{arg_name} in #{receiver_type}##{message}", self)
              else
                unless actual_argument.nil? # opt if this is nil
                  actual_argument_type = actual_argument.check_type(context)
                  unless actual_argument_type.compatible?(from_type)
                    error_message = "#{error_message} #{from_type} expected, #{argument_type} found"
                    fail TypeError.new(error_message, self)
                  end
                end
              end
            end
            self
          end
        end

        class TyGenericFunction < TyFunction
          attr_accessor :local_typing_context

          def initialize(from, to, parameters_info = nil)
            super(from, to, parameters_info)
            @local_typing_context = local_typing_context
            @application_count = 0
          end

          def materialize
            fail StandardError, 'Cannot materialize function because of missing local typing context' if @local_typing_context.nil?
            materialized_from_args = []
            materialized_to_arg = nil

            @application_count += 1
            substitutions = @local_typing_context.local_var_types.each_with_object({}) do |var_type, acc|
              acc[var_type.variable] = Polymorphism::TypeVariable.new("#{var_type}_#{@application_count}")
              maybe_from_arg_index = from.index(var_type)
              if maybe_from_arg_index
                materialized_from_args[maybe_from_arg_index] = acc[var_type.variable]
              end
              if to == var_type
                materialized_to_arg = acc[var_type.variable]
              end
            end

            if materialized_from_args.size != from.size
              fail StandardError, "Cannot find all the type variables for function application in the local typing context, expected #{from.size} got #{materialized_from_args.size}."
            end

            if materialized_to_arg.nil?
              fail StandardError, "Cannot find the return type variable for function application in the local typing context."
            end
            applied_typing_context = @local_typing_context.apply_type(@local_typing_context.parent, substitutions)
            materialized_function = TyFunction.new(materialized_from_args, materialized_to_arg, parameters_info)
            TypingContext.with_context(applied_typing_context) do
              yield materialized_function
            end

            # got all the constraints here
            # do something with the context -> unification? merge context?
            Polymorphism::Unification.new(applied_typing_context.all_constraints).run
            bound_from_args = materialized_function.from.map  { |arg| arg.bound || arg }
            bound_to_arg = materialized_function.to.bound || materialized_function.to
            #
            TyFunction.new(bound_from_args, bound_to_arg, parameters_info)
          end

          def check_args_application(actual_arguments, context)
            materialize do |materialized_function|
              materialized_function.check_args_application(actual_arguments, context)
            end
          end
        end
      end
    end
  end
end
