# -*- coding: utf-8 -*-
require_relative '../model'

module TypedRb
  module Model
    # A instance/class function definition expression
    class TmFun < Expr
      attr_accessor :name, :args, :body, :owner

      def initialize(owner, name, args, body, node)
        super(node)
        @owner = parse_owner(owner)
        @name = name
        rename = {}
        # This is safe, within the function, args names are bound
        # to this reference
        @args = args.map do |arg|
          old_id = arg[1].to_s
          uniq_arg = Model::GenSym.next(old_id)
          rename[old_id] = uniq_arg
          arg[1] = uniq_arg
          arg
        end
        @body = rename.inject(body) do |body_acc, (old_id, new_id)|
          body_acc.rename(old_id, new_id)
        end
      end

      def rename(from_binding, to_binding)
        # rename receiver
        if owner != :self
          @owner = @owner.rename(from_binding, to_binding)
        end
        # rename default args
        args.each do |arg|
          if arg.first == :optarg
            arg[2] = arg[2].rename(from_binding, to_binding)
          end
        end
        #rename free variables -> not bound (and already renamed) in args
        @body = @body.rename(from, to_binding)
        self
      end

      def check_type(context)
        owner_type, is_constructor  = if owner == :self
                                        [context.get_self,
                                         (name == :initialize &&
                                          context.get_self.instance_of?(
                                            Types::TySingletonObject))]
                                      elsif owner.nil?
                                        [context.get_self.as_object_type,
                                         (name == :initialize &&
                                          context.get_self.instance_of?(
                                            Types::TySingletonObject))]
                                      else
                                        [owner.check_type(context),
                                         (name == :initialize &&
                                          owner.instance_of?(
                                            Types::TySingletonObject))]
                                      end


        if owner_type.nil?
          fail TypeCheckError.new("Error type checking function #{owner}##{name}: Cannot find owner type for #{owner}", node)
        end
        arg_count = args.count { |arg| arg.first != :blockarg }
        function_klass_type, function_type = owner_type.find_function_type(name, arg_count)
        if function_type.nil? || function_type.is_a?(Types::TyDynamicFunction)
          # fail TypeCheckError.new("Error type checking function #{owner}##{name}: Cannot find function type information for owner.", node)
          # Missing type information stops the type checking process
          # TODO: raise a warning here about the previous fact
          # fail TypeCheckError.new("Error type checking function #{owner}##{name}: Cannot find function type information for owner.", node)
        else
          # check matching args
          if function_type.from.size < args.select { |(arg_type, _)| arg_type == :arg }.size
            if function_klass_type != owner_type.ruby_type
              Types::TyDynamicFunction.new(owner_type.ruby_type, name)
            else
              fail TypeCheckError.new("Error type checking function #{owner}##{name}: Number of arguments don't match type signature, expected #{function_type.from.size} found #{args.size}.", node)
            end
          end


          orig_context = context.dup

          args.each_with_index do |arg, i|
            function_arg_type = function_type.from[i]
            # Generic arguments are parsed by runtime without checking constraints since they are not available at parsing type.
            # We need to run unification in them before using the type to detect invalid type argument applications.
            function_arg_type = function_arg_type.self_materialize if function_arg_type.is_a?(Types::TyGenericSingletonObject)
            context = case arg.first
                      when :arg, :restarg
                        context.add_binding(arg[1], function_arg_type)
                      when :optarg
                        declared_arg_type = arg.last.check_type(orig_context)
                        if declared_arg_type.compatible?(function_arg_type)
                          context.add_binding(arg[1], function_arg_type)
                        else
                          error_message = "Error type checking function #{owner}##{name}: Expected arg #{arg[1]} with type #{function_arg_type}, found type #{declared_arg_type}"
                          fail TypeCheckError.new(error_message, node)
                        end
                      when :blockarg
                        if(function_type.block_type)
                          context.add_binding(arg[1], function_type.block_type)
                        else
                          fail TypeCheckError.new("Error type checking function #{owner}##{name}: Missing block type for block argument #{arg[1]}", node)
                        end
                      else
                        fail TypeCheckError.new("Error type checking function #{owner}##{name}: Unknown type of arg #{arg.first}", node)
                      end
          end

          # pointing self to the right type
          self_type = if owner_type.is_a?(Types::TyExistentialType)
                        owner_type.self_variable
                      else
                        owner_type
                      end
          context = context.add_binding(:self, self_type)

          # adding yield binding if present
          context = context.add_binding(:yield, function_type.block_type) if function_type.block_type

          if is_constructor
            # constructor
            with_fresh_bindings(function_klass_type, function_type, context, node) do
              body.check_type(context)
              function_type
            end
          else
            # check the body with the new bindings for the args
            with_fresh_bindings(function_klass_type, function_type, context, node) do
              body_return_type = body.check_type(context)
              if body_return_type.is_a?(TmReturn)
                body_return_type = body_return_type.check_type(context)
              end
              if function_type.to.instance_of?(Types::TyUnit)
                function_type.to
              else
                # Same as before but for the return type
                function_type_to = function_type.to.is_a?(Types::TyGenericSingletonObject) ? function_type.to.self_materialize : function_type.to
                if body_return_type.compatible?(function_type_to, :lt)
                  function_type
                # TODO:
                # A TyObject(Symbol) should be returned not the function type
                # x = def id(x); x; end / => x == :id
                else
                  error_message = "Error type checking function type #{owner}##{name}: Wrong return type, expected #{function_type.to}, found #{body_return_type}."
                  fail TypeCheckError.new(error_message, node)
                end
              end
            end
          end
        end
      end

      # TODO:
      # 1 Find free type variables for the generic function.
      # 2 Create a new local typing context for the generic function
      # 3 Add free type variables to the typing context
      def with_fresh_bindings(klass, function_type, context, node)
        if function_type.generic?
          Types::TypingContext.push_context(:method)
          function_type.free_type_variables(klass).each do |type_var|
            # This will add the variable to the context
            Types::TypingContext.type_variable_for_function_type(type_var)
          end

          yield

          # # Since every single time we find the generic type the same instance
          # # will be returned, the local_typing_context will still be associated.
          # # This is the reason we need to build a new typing context cloning this
          # # one while type materialization.
          function_type.local_typing_context = Types::TypingContext.pop_context
        else
          yield
        end
        function_type
      end

      private

      def parse_owner(owner)
        if owner.nil?
          nil
        elsif owner == :self || owner.type == :self
          :self
        else # must be a class or other expression we can check the type
          owner
        end
      end
    end
  end
end
