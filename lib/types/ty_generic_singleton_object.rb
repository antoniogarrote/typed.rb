require_relative 'ty_singleton_object'
require_relative 'polymorphism/generic_comparisons'

module TypedRb
  module Types
    class TyGenericSingletonObject < TySingletonObject
      include Polymorphism::GenericComparisons

      attr_accessor :local_typing_context, :super_type

      def initialize(ruby_type, type_vars, super_type = nil, node = nil)
        super(ruby_type, node)
        @super_type = super_type
        @type_vars = type_vars
        @application_count = 0
      end

      def type_vars(options = { recursive: true })
        return @type_vars unless options[:recursive]
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

      def materialize_with_type_vars(type_vars, bound_type)
        TypedRb.log binding, :debug, "Materialising generic singleton object with type vars '#{self}' <= #{type_vars.map(&:to_s).join(',')} :: #{bound_type}"
        bound_type_vars = self.type_vars.map do |type_var|
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
        materialize(bound_type_vars.map { |bound_type_var| bound_type_var.send(bound_type) })
      end

      def self_materialize
        TypedRb.log binding, :debug, "Materialising self for generic singleton object '#{self}'"
        BasicObject::TypeRegistry.find_generic_type(ruby_type).materialize(type_vars)
      end

      # materialize will be invoked by the logic handling invocations like:
      # ts 'MyClass[X][Y]'
      # class MyClass
      #  ...
      # end
      # MyClass.(TypeArg1, TypeArg2)  -> make X<TypeArg1, Y<TypeArg2, X>TypeArg1, X>TypeArg2
      # MyClass.(TypeArg1, TypeArg2)  -> Materialize here > make X<TypeArg1, Y<TypeArg2 > Unification
      def materialize(actual_arguments)
        TypedRb.log binding, :debug, "Materialising generic singleton object '#{self}' with args [#{actual_arguments.map(&:to_s).join(',')}]"
        # This can happen when we're dealing with a generic singleton object that has only been
        # annotated but we don't have the annotated implementation. e.g. Array[T]
        # We need to provide a default local_type_context based on the upper bounds provided in the
        # type annotation.
        compute_minimal_typing_context if @local_typing_context.nil?

        applied_typing_context, substitutions = @local_typing_context.clone(:class)
        fresh_vars_generic_type = clone_with_substitutions(substitutions)
        TypingContext.with_context(applied_typing_context) do
          # Appy constraints for application of Type args
          apply_type_arguments(fresh_vars_generic_type, actual_arguments)
        end
        # got all the constraints here
        # do something with the context -> unification? merge context?
        # applied_typing_context.all_constraints.each{|(l,t,r)| puts "#{l} #{t} #{r}" }
        unification = Polymorphism::Unification.new(applied_typing_context.all_constraints).run
        applied_typing_context.unlink # these constraints have already been satisfied
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
        TyGenericObject.new(ruby_type, @type_vars)
      end

      def compute_minimal_typing_context
        Model::TmClass.with_fresh_bindings(self, nil, node)
      end

      def generic?
        true
      end

      def apply_bindings(bindings_map)
        type_vars(recursive: false).each_with_index do |var, _i|
          if var.is_a?(Polymorphism::TypeVariable) && var.bound_to_generic?
            var.bind(var.bound.apply_bindings(bindings_map))
          elsif var.is_a?(Polymorphism::TypeVariable)
            var.apply_bindings(bindings_map)
          elsif var.is_a?(TyGenericSingletonObject) || var.is_a?(TyGenericObject)
            var.apply_bindings(bindings_map)
          end
        end
        self
      end

      def clone
        cloned_type_vars = type_vars.map(&:clone)
        TyGenericSingletonObject.new(ruby_type, cloned_type_vars, super_type, node)
      end

      def to_s
        base_string = super
        var_types_strings = @type_vars.map do |var_type|
          if !var_type.is_a?(Polymorphism::TypeVariable)
            "[#{var_type}]"
          elsif var_type.bound && var_type.bound.is_a?(Polymorphism::TypeVariable)
            "[#{var_type.variable} <= #{var_type.bound.bound || var_type.bound.variable}]"
          else
            "[#{var_type.bound || var_type.variable}]"
          end
        end
        "#{base_string}#{var_types_strings.join}"
      end

      def clone_with_substitutions(substitutions)
        materialized_type_vars = type_vars(recursive: false).map do |type_var|
          if type_var.is_a?(Polymorphism::TypeVariable) && type_var.bound_to_generic?
            new_type_var = Polymorphism::TypeVariable.new(type_var.variable, node: type_var.node, gen_name: false)
            new_type_var.to_wildcard! if type_var.wildcard?
            bound = type_var.bound.clone_with_substitutions(substitutions)
            new_type_var.bind(bound)
            new_type_var.upper_bound = bound if type_var.upper_bound
            new_type_var.lower_bound = bound if type_var.lower_bound
            new_type_var
          elsif type_var.is_a?(Polymorphism::TypeVariable)
            substitutions[type_var.variable] || type_var.clone
          elsif type_var.is_a?(TyGenericSingletonObject) || type_var.is_a?(TyGenericObject)
            type_var.clone_with_substitutions(substitutions)
          else
            type_var
          end
        end
        self.class.new(ruby_type, materialized_type_vars, super_type, node)
      end

      protected

      def apply_type_arguments(fresh_vars_generic_type, actual_arguments)
        fresh_vars_generic_type.type_vars.each_with_index do |type_var, i|
          if type_var.bound.is_a?(TyGenericSingletonObject)
            type_var.bind(apply_type_arguments_recursively(type_var.bound, actual_arguments))
          else
            apply_type_argument(actual_arguments[i], type_var)
          end
        end
      end

      def apply_type_argument(argument, type_var)
        if argument.is_a?(Polymorphism::TypeVariable)
          if argument.wildcard?
            # Wild card type
            # If the type is T =:= E < Type1 or E > Type1 only that constraint should be added
            { :lt => :upper_bound, :gt => :lower_bound }.each do |relation, bound|
              if argument.send(bound)
                value = if argument.send(bound).is_a?(TyGenericSingletonObject)
                          argument.send(bound).clone # .self_materialize
                        else
                          argument.send(bound)
                        end
                type_var.compatible?(value, relation)
              end
            end
            type_var.to_wildcard! # WILD CARD
          elsif argument.bound # var type with a particular value
            argument = argument.bound
            if argument.is_a?(TyGenericSingletonObject)
              argument = argument.clone # .self_materialize
            end
            # This is only for matches T =:= Type1 -> T < Type1, T > Type1
            fail Types::UncomparableTypes.new(type_var, argument) unless type_var.compatible?(argument, :lt)
            fail Types::UncomparableTypes.new(type_var, argument) unless type_var.compatible?(argument, :gt)
          else
            # Type variable
            type_var.bound = argument
            type_var.lower_bound = argument
            type_var.upper_bound = argument
          end
        else
          if argument.is_a?(TyGenericSingletonObject)
            argument = argument.clone # .self_materialize
          end
          # This is only for matches T =:= Type1 -> T < Type1, T > Type1
          fail Types::UncomparableTypes.new(type_var, argument) unless type_var.compatible?(argument, :lt)
          fail Types::UncomparableTypes.new(type_var, argument) unless type_var.compatible?(argument, :gt)
        end
      end

      def apply_type_arguments_recursively(generic_type_bound, actual_arguments)
        arg_names = actual_arguments_hash(actual_arguments)
        recursive_actual_arguments = generic_type_bound.type_vars.map do |type_var|
          arg_names[type_var.variable] || fail("Unbound type variable #{type_var.variable} for recursive generic type #{generic_type_bound}")
        end
        generic_type_bound.materialize(recursive_actual_arguments)
      end

      def actual_arguments_hash(actual_arguments)
        acc = {}
        type_vars.each_with_index do |type_var, i|
          acc[type_var.variable] = actual_arguments[i]
        end
        acc
      end
    end
  end
end
