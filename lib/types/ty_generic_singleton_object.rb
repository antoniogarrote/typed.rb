require_relative 'ty_singleton_object'
require_relative 'polymorphism/generic_comparisons'

module TypedRb
  module Types
    class TyGenericSingletonObject < TySingletonObject

      include Polymorphism::GenericComparisons

      attr_reader :type_vars
      attr_accessor :local_typing_context

      def initialize(ruby_type, type_vars)
        super(ruby_type)
        @type_vars = type_vars
        @application_count = 0
      end

      # ts 'MyClass[X][Y]'
      # class MyClass
      #  ...
      # end
      # MyClass.(TypeArg1, TypeArg2)  -> make X<TypeArg1, Y<TypeArg2, X>TypeArg1, X>TypeArg2
      # @see comment below
      # TODO: what if we want to materialize with a type variable? => def x:T; Array.(T).new; end
      def materialize(actual_arguments, context)
        with_fresh_var_types do |fresh_vars_generic_type|
          actual_arguments.each_with_index do |argument, i|
            if argument.is_a?(Polymorphism::TypeVariable)
              # If the type is T =:= E < Type1 or E > Type1 only that constraint should be added
              if argument.upper_bound
                fresh_vars_generic_type.type_vars[i].compatible?(argument.upper_bound, :lt)
              end
              if argument.lower_bound
                fresh_vars_generic_type.type_vars[i].compatible?(argument.lower_bound, :gt)
              end
            else
              # This is only for matches T =:= Type1 -> T < Type1, T > Type1
              fresh_vars_generic_type.type_vars[i].compatible?(argument, :lt)
              fresh_vars_generic_type.type_vars[i].compatible?(argument, :gt)
            end
          end
        end
      end

      def materialize_with_type_vars(type_vars, bound_type)
        bound_type_vars = @type_vars.map do |type_var|
          type_vars.detect do |bound_type_var|
            type_var.variable == bound_type_var.variable
          end
        end
        materialize(bound_type_vars.map{ |type_var| type_var.send(bound_type) }, nil)
      end
      # materialize will be invoked by the logic handling invocations like:
      # ts 'MyClass[X][Y]'
      # class MyClass
      #  ...
      # end
      #
      # MyClass.(TypeArg1, TypeArg2)  -> Materialize here > make X<TypeArg1, Y<TypeArg2 > Unification
      def with_fresh_var_types
        # This can happen when we're dealing with a generic singleton object that has only been
        # annotated but we don't have the annotated implementation. e.g. Array[T]
        # We need to provide a default local_type_context based on the upper bounds provided in the
        # type annotation.
        if @local_typing_context.nil?
          @local_typing_context = minimal_typing_context
          #fail StandardError, 'Cannot generate fresh var types for generic class because of missing local typing context'
        end

        @application_count += 1
        substitutions = @local_typing_context.generic_type_local_var_types.each_with_object({}) do |type_var, acc|
          cloned_type_var = Polymorphism::TypeVariable.new("#{type_var.variable}_#{@application_count}")
          cloned_type_var.upper_bound = type_var.upper_bound
          cloned_type_var.lower_bound = type_var.lower_bound
          acc[type_var.variable] = cloned_type_var
        end
        applied_typing_context = @local_typing_context.apply_type(@local_typing_context.parent, substitutions)
        fresh_type_vars = type_vars.map do |type_var|
          applied_typing_context.type_variables_register[[:generic, nil, type_var.variable]]
        end

        fresh_vars_generic_type = TyGenericSingletonObject.new(ruby_type, fresh_type_vars)
        fresh_vars_generic_type.local_typing_context = applied_typing_context
        TypingContext.with_context(applied_typing_context) do
          # Appy constraints for application of Type args
          yield fresh_vars_generic_type
        end

        # got all the constraints here
        # do something with the context -> unification? merge context?
        # applied_typing_context.all_constraints.each{|(l,t,r)| puts "#{l} #{t} #{r}" }
        Polymorphism::Unification.new(applied_typing_context.all_constraints).run
        # - Create a new ty_generic_object for the  unified types

        # Better not the type of the bound var type var but the var type itself,
        # it can be used to look for the var in applications
        fresh_type_vars = fresh_type_vars.map do |type_var|
          # TODO: nested type vars?
          # class X[T]; def test; Array.(T).new; end; end
          orig_name = applied_typing_context.type_variables_register.invert[type_var].last
          type_var.variable= orig_name
          if type_var.bound.nil?
            fail TypedRb::TypeCheckError, "Found unbound var #{orig_name} for generic type #{self} after unification in materialization."
          end
          type_var
        end

        # - Apply the unified types to all the methods in the class/instance
        #   - this can be dynamically done with the right implementation of find_function_type
        # - Make the class available for the type checking system, so it can be found when
        #   - this can be done, just returning the new ty_singleton_object with the unified types
        #   - messages will be redirected to that instance and find_function_type/ find_var_type / as_object
        #     will handle the mesage
        # - looking for messages at the instance level
        #   - this can be accomplished with the overloading version of as_object_type, that will return
        #     an instance of a new class ty_generic_object with overloaded versions of find_function_type /find_var_type
        ########################

        TyGenericSingletonObject.new(ruby_type, fresh_type_vars)
      end

      # TODO: We do need this for cases like Array.(Int).class_method

      # def find_function_type(message)
      #   function_type = BasicObject::TypeRegistry.find(:class, ruby_type, message)
      #   replace_bound_type_vars(function_type, type_vars)
      # end

      #          def find_function_type(message)
      #            BasicObject::TypeRegistry.find(:class, ruby_type, message)
      #          end
      #
      #          def find_var_type(var)
      #            var_type = BasicObject::TypeRegistry.find(:class_variable, ruby_type, var)
      #            if var_type
      #              var_type
      #            else
      #              Types::TypingContext.type_variable_for(:class_variable, var, hierarchy)
      #            end
      #          end

      def as_object_type
        # this should only be used to check the body type of this
        # class. The variables are going to be unbound.
        # This is also used in instantiation of the generic object.
        TyGenericObject.new(ruby_type, type_vars)
      end

      def minimal_typing_context
        Model::TmClass.with_fresh_bindings(self, nil)
        self.local_typing_context
      end

      def to_s
        base_string = super
        var_types_strings = @type_vars.map do |var_type|
          "[#{var_type.bound || var_type.variable}]"
        end
        "#{base_string}#{var_types_strings.join}"
      end
    end
  end
end
