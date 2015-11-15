module TypedRb
  module Types
    module Polymorphism
      module GenericVariables
        def type_vars(options = { recursive: true })
          return @type_vars unless options[:recursive]
          return @type_vars if self.class == TypedRb::Types::TyGenericObject
          @type_vars.map do |type_var|
            if type_var.is_a?(Polymorphism::TypeVariable) && type_var.bound_to_generic?
              type_var.bound.type_vars
            elsif type_var.is_a?(Polymorphism::TypeVariable)
              type_var
            else
              type_var.type_vars
            end
          end.flatten
          #  .each_with_object({}) do |type_var, acc|
          #  acc[type_var.variable] = type_var
          #end.values
        end
      end
    end
  end
end
