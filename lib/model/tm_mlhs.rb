require_relative '../model'
require_relative '../types/ty_generic_object'

module TypedRb
  module Model
    # Deconstructing arg variables
    class TmMlhs < Expr
      attr_accessor :args
      def initialize(args, node)
        @args = args
      end

      def check_type(actual_argument, context)
        if pair_argument?(actual_argument)
          process_pair(actual_argument, context)
        elsif array_argument?(actual_argument)
          process_array(actual_argument, context)
        else
          process_other(actual_argument, context)
        end
      end

      def rename
        rename = {}
        @args = args.map do |arg|
          old_id = arg.to_s
          uniq_arg = Model::GenSym.next(old_id)
          rename[old_id] = uniq_arg
          uniq_arg
        end
        rename
      end

      protected

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

      def process_other(actual_argument, context)
        args.each_with_index do |arg, i|
          type = case i
                 when 0
                   actual_argument
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
