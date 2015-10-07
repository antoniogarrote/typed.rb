require_relative '../model'
require_relative '../types/ty_generic_object'

module TypedRb
  module Model
    # Deconstructing arg variables
    class TmMlhs < Expr
      attr_accessor :args, :lambda_args
      def initialize(args, node)
        super(node)
        @args = args
      end

      def check_type(actual_argument, context)
        return process_lambda_args(context) if actual_argument == :lambda
        if pair_argument?(actual_argument)
          process_pair(actual_argument, context)
        elsif array_argument?(actual_argument)
          process_array(actual_argument, context)
        else
          fail TypeCheckError.new("Error type checking function MLHS term: Type is not subtype of Array:  #{actual_argument}", node)
        end
      end

      def compatible?(other_type, relation = :lt)
        if other_type.generic? && other_type.ruby_type.ancestors.include?(Array)
          if other_type.type_vars.size == 1
            @lambda_args.each do |lambda_arg|
              lambda_arg.compatible?(other_type.type_vars.first, relation)
            end
          elsif other_type.type_vars.size == @lambda_args.size
            @lambda_args.each_with_object do |lambda_arg, i|
              lambda_arg.compatible?(other_type.type_vars[i], relation)
            end
          else
            false
          end
        else
          false
        end
      end

      protected

      def process_lambda_args(context)
        @lambda_args = args.map do |arg|
          type_var = Types::TypingContext.type_variable_for_abstraction(:lambda, arg.to_s, context)
          type_var.node = node
          context = context.add_binding(arg, type_var)
          type_var
        end
        context
      end

      def process_array(actual_argument, context)
        type_var = actual_argument.type_vars[0]
        args.each { |arg| context = context.add_binding(arg, type_var) }
        context
      end

      def process_pair(actual_argument, context)
        args.each_with_index do |arg, i|
          type = case i
                 when 0
                   actual_argument.type_vars[0]
                 when 1
                   actual_argument.type_vars[1]
                 else
                   Types::TyUnit.new(node)
                 end
          context = context.add_binding(arg, type)
        end
        context
      end

      def array_argument?(argument)
        argument.is_a?(Types::TyGenericObject) &&
          argument.ruby_type.ancestors.include?(Array)
      end

      def pair_argument?(argument)
        argument.is_a?(Types::TyGenericObject) &&
          argument.ruby_type.ancestors.include?(Pair)
      end
    end
  end
end
