require_relative '../model'

module TypedRb
  module Model
    class TmRescue < Expr

      attr_reader :exceptions, :catch_var, :rescue_body
      def initialize(exceptions, catch_var, rescue_body)
        @exceptions = exceptions
        @catch_var = catch_var
        @rescue_body = rescue_body
      end

      def check_type(context)
        if catch_var
          exception_type = exceptions.map{|e| e.check_type(context) }.reduce(&:max)
          context.add_binding!(catch_var, exception_type)
        end
        if rescue_body
          rescue_body.check_type(context)
        else
          Types::TyUnit.new
        end
      end
    end
  end
end
