module TypedRb
  module Languages
    module PolyFeatherweightRuby
      module Types
        class TySingletonObject < TyObject

          def initialize(ruby_type)
            super(ruby_type)
          end

          def find_function_type(message)
            BasicObject::TypeRegistry.find(:class, ruby_type, message)
          end

          def find_var_type(var)
            var_type = BasicObject::TypeRegistry.find(:class_variable, ruby_type, var)
            if var_type
              var_type
            else
              Types::TypingContext.type_variable_for(:class_variable, var, hierarchy)
            end
          end

          def resolve_ruby_method(message)
            @ruby_type.singleton_method(message)
          end

          def as_object_type
            TyObject.new(ruby_type)
          end

          def to_s
            "Class[#{@ruby_type.name}]"
          end
        end

        class TyGenericSingletonObject < TySingletonObject

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
          # MyClass.(TypeArg1, TypeArg2)  -> make X<TypeArg1, Y<TypeArg2
          # @see comment below
          def check_args_application(actual_arguments, context)
            materialize do |materialized_generic_type|
              actual_arguments.each_with_index do |argument, i|
                materialized_generic_type.type_vars[i].compatible?(argument, :lt)
              end
            end
          end

          # materialize will be invoked by the logic handling invocations like:
          # ts 'MyClass[X][Y]'
          # class MyClass
          #  ...
          # end
          #
          # MyClass.(TypeArg1, TypeArg2)  -> Materialize here > make X<TypeArg1, Y<TypeArg2 > Unification
          def materialize
            if @local_typing_context.nil?
              fail StandardError, 'Cannot materialize generic class because of missing local typing context'
            end

            @application_count += 1
            substitutions = @local_typing_context.generic_type_local_var_types.each_with_object({}) do |type_var, acc|
              cloned_type_var = Polymorphism::TypeVariable.new("#{type_var.variable}_#{@application_count}")
              cloned_type_var.upper_bound = type_var.upper_bound
              acc[type_var.variable] = cloned_type_var
            end
            applied_typing_context = @local_typing_context.apply_type(@local_typing_context.parent, substitutions)
            materialized_type_vars = type_vars.map do |type_var|
              applied_typing_context.type_variables_register[[:generic, nil, type_var.variable]]
            end

            materialized_generic_type = TyGenericSingletonObject.new(ruby_type, materialized_type_vars)
            materialized_generic_type.local_typing_context = applied_typing_context
            TypingContext.with_context(applied_typing_context) do
              # Appy constraints for application of Type args
              yield materialized_generic_type
            end

            # got all the constraints here
            # do something with the context -> unification? merge context?
            # applied_typing_context.all_constraints.each{|(l,t,r)| puts "#{l} #{t} #{r}" }
            Polymorphism::Unification.new(applied_typing_context.all_constraints).run
            # - Create a new ty_singleton_object for the  unified types

            # Better not the the type but the bound type var but the var itself,
            # it can be used to look for the var in applications
             materialized_type_vars = materialized_type_vars.map do |type_var|
               # TODO: nested type vars?
               # class X[T]; def test; Array.(T).new; end; end
               orig_name = applied_typing_context.type_variables_register.invert[type_var].last
               type_var.variable= orig_name
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

            TyGenericSingletonObject.new(ruby_type, materialized_type_vars)
          end

          # TODO
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
            TyGenericObject.new(ruby_type, type_vars)
          end
        end
      end
    end
  end
end
