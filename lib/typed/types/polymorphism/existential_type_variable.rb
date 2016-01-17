require_relative './type_variable'
module TypedRb
  module Types
    module Polymorphism
      class ExistentialTypeVariable < TypeVariable
        attr_accessor :module_type
        def find_var_type(var)
          module_type.find_var_type(var)
        end
      end
    end
  end
end
