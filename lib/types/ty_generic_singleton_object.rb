require_relative 'ty_singleton_object'
require_relative 'polymorphism/generic_comparisons'

module TypedRb
  module Types
    class TyGenericSingletonObject < TySingletonObject

      include Polymorphism::GenericComparisons

      attr_reader :type_vars
      attr_accessor :local_typing_context

      def initialize(ruby_type, type_vars, node = nil)
        super(ruby_type, node)
        @type_vars = type_vars
        @application_count = 0
      end

      def materialize_with_type_vars(type_vars, bound_type)
        TypedRb.log binding, :debug, "Materialising generic singleton object with type vars '#{self}' <= #{type_vars.map(&:to_s).join(',')} :: #{bound_type}"
        bound_type_vars = @type_vars.map do |type_var|
          maybe_class_bound = type_vars.detect do |bound_type_var|
            type_var.variable == bound_type_var.variable
          end
          if maybe_class_bound.nil?
            # it has to be method generic variable
            type_var
          else
            maybe_class_bound
          end
        end
        materialize(bound_type_vars.map{ |type_var| type_var.send(bound_type) })
      end

      def self_materialize
        TypedRb.log binding, :debug, "Materialising self for generic singleton object '#{self}'"
        BasicObject::TypeRegistry.find_generic_type(ruby_type).materialize(type_vars)
      end

      # ts 'MyClass[X][Y]'
      # class MyClass
      #  ...
      # end
      # MyClass.(TypeArg1, TypeArg2)  -> make X<TypeArg1, Y<TypeArg2, X>TypeArg1, X>TypeArg2
      # @see comment below
      def materialize(actual_arguments)
        TypedRb.log binding, :debug, "Materialising generic singleton object '#{self}' with args [#{actual_arguments.map(&:to_s).join(',')}]"

        with_fresh_var_types do |fresh_vars_generic_type|
          actual_arguments.each_with_index do |argument, i|
            if argument.is_a?(Polymorphism::TypeVariable)
              if argument.name.index(':?')
                # Wild card type
                # If the type is T =:= E < Type1 or E > Type1 only that constraint should be added
                { :lt => :upper_bound, :gt => :lower_bound }.each do |relation, bound|
                  if argument.send(bound)
                    value = if argument.send(bound).is_a?(TyGenericSingletonObject)
                              argument.send(bound).self_materialize
                            else
                              argument.send(bound)
                            end
                    fresh_vars_generic_type.type_vars[i].compatible?(value, relation)
                  end
                end
              else
                # Type variable
                fresh_vars_generic_type.type_vars[i].bound = argument
                fresh_vars_generic_type.type_vars[i].lower_bound = argument
                fresh_vars_generic_type.type_vars[i].upper_bound = argument
              end
            else
              if argument.is_a?(TyGenericSingletonObject)
                argument = argument.self_materialize
              end
              # This is only for matches T =:= Type1 -> T < Type1, T > Type1
              fresh_vars_generic_type.type_vars[i].compatible?(argument, :lt)
              fresh_vars_generic_type.type_vars[i].compatible?(argument, :gt)
            end
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
      def with_fresh_var_types
        # This can happen when we're dealing with a generic singleton object that has only been
        # annotated but we don't have the annotated implementation. e.g. Array[T]
        # We need to provide a default local_type_context based on the upper bounds provided in the
        # type annotation.
        if @local_typing_context.nil?
          compute_minimal_typing_context
        end
        fresh_vars_generic_type = TypingContext.duplicate(self)
        applied_typing_context = fresh_vars_generic_type.local_typing_context

        TypingContext.with_context(applied_typing_context) do
          # Appy constraints for application of Type args
          yield fresh_vars_generic_type
        end
        # got all the constraints here
        # do something with the context -> unification? merge context?
        # applied_typing_context.all_constraints.each{|(l,t,r)| puts "#{l} #{t} #{r}" }
        unification = Polymorphism::Unification.new(applied_typing_context.all_constraints).run
        # - Create a new ty_generic_object for the  unified types
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
        fresh_vars_generic_type.apply_bindings(unification.bindings_map)
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

      def compute_minimal_typing_context
        Model::TmClass.with_fresh_bindings(self, nil, node)
      end

      def generic?
        true
      end

      def apply_bindings(bindings_map)
        type_vars.each_with_index do |var, i|
          if var.is_a?(Polymorphism::TypeVariable)
            var.apply_bindings(bindings_map)
            #type_vars[i] = var.bound if var.bound
          elsif var.is_a?(TyGenericSingletonObject) || var.is_a?(TyGenericObject)
            var.apply_bindings(bindings_map)
          end
        end
        self
      end

      def to_s
        base_string = super
        var_types_strings = @type_vars.map do |var_type|
          if var_type.bound && var_type.bound.is_a?(Polymorphism::TypeVariable)
            "[#{var_type.variable} <= #{var_type.bound.bound || var_type.bound.variable}]"
          else
            "[#{var_type.bound || var_type.variable}]"
          end
        end
        "#{base_string}#{var_types_strings.join}"
      end
    end
  end
end
