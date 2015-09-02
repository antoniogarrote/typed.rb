require_relative '../runtime'

module TypedRb
  module Runtime
    class TypeParser
      class << self
        def parse(type, klass)
          fail TypeParsingError, 'Error parsing type: nil value.' if type.nil?
          if type == 'unit'
            Types::TyUnit.new
          elsif type == 'Boolean'
            Types::TyBoolean.new
          elsif type.is_a?(Array)
            parse_function_type(type, klass)
          elsif type.is_a?(Hash) && (type[:kind] == :type_var || type[:kind] == :method_type_var)
            maybe_class = Object.const_get(type[:type]) rescue false
            if maybe_class
              type[:type] = maybe_class
            else
              type[:type] = "#{klass}:#{type[:type]}"
            end
            parse_type_var(type)
          elsif type.is_a?(Hash) && type[:kind] == :generic_type
            parse_concrete_type(type, klass)
          elsif type.is_a?(Hash) && type[:kind] == :rest
            parse_rest_args(type, klass)
          else
            parse_object_type(type)
          end
        end

        def parse_type_var(type)
          if type[:binding] == '<'
            Types::Polymorphism::TypeVariable.new(type[:type],
                                                  :upper_bound => Types::TySingletonObject.new(Object.const_get(type[:bound])),
                                                  :gen_name    => false)
          elsif type[:binding] == '>'
            Types::Polymorphism::TypeVariable.new(type[:type],
                                                  :lower_bound => Types::TySingletonObject.new(Object.const_get(type[:bound])),
                                                  :gen_name    => false)
          elsif type[:type].is_a?(Class)
            type_var = Types::Polymorphism::TypeVariable.new(nil,
                                                             :gen_name => false,
                                                             :upper_bound => type[:type],
                                                             :lower_bound => type[:type])
            type_var.bind(type[:type])
            type_var
          else
            Types::Polymorphism::TypeVariable.new(type[:type], :gen_name => false)
          end
        end

        def parse_rest_args(type,  klass)
          parsed_parameter = parse(type[:parameters].first, klass)
          if parsed_parameter.is_a?(Types::Polymorphism::TypeVariable)
            #TODO: should I use #parse_singleton_object_type here?
            Types::TyGenericSingletonObject.new(Array, [parsed_parameter])
          else
            type_var = Types::Polymorphism::TypeVariable.new('Array:T', :gen_name => false,
                                                      :upper_bound => parsed_parameter,
                                                      :lower_bound => parsed_parameter)
            type_var.bind(parsed_parameter)
            Types::TyGenericObject.new(Array, [type_var])
          end
        end

        def parse_concrete_type(type, klass)
          # parameter_names -> container class type vars
          TypedRb.log(binding, :debug, "Parsing concrete type #{type} within #{klass}")

          parameter_names = BasicObject::TypeRegistry.type_vars_for(klass).each_with_object({}) do |variable, acc|
            acc[variable.name.split(':').last] = variable
          end
          # this is the concrete argument to parse
          # it might refer to type vars in the container class
          ruby_type = Object.const_get(type[:type])
          is_generic = false
          concrete_type_vars = []
          # for each parameter:
          # - klass.is_variable? -> variable -> generic singletion
          # - klass.is not variable? ->  bound_type -> generic object
          rrt = BasicObject::TypeRegistry.type_vars_for(ruby_type)
          rrt.each_with_index do |type_var, i|
            param = type[:parameters][i]
            maybe_bound_param = parameter_names[param[:type]]
            parsed_type_var = if maybe_bound_param
                                is_generic = true
                                maybe_bound_param
                              else
                                if param[:kind] == :generic_type
                                  # It is a nested generic type
                                  klass = Object.const_get(param[:type])
                                  bound = parse(param, klass)
                                  concrete_param = Types::Polymorphism::TypeVariable.new(type_var.name,
                                                                                         :upper_bound => bound,
                                                                                         :lower_bound => bound,
                                                                                         :gen_name => false)
                                  concrete_param.bind(bound)
                                  is_generic = bound.is_a?(Types::TyGenericSingletonObject) ? true : false
                                  concrete_param
                                elsif param[:bound]
                                  # A type parameter that is not bound in the generic type declaration.
                                  # It has to be local to the method (TODO: not implemented yet)
                                  # or a wildcard '?'
                                  is_generic = true
                                  # TODO: add some reference to the method if the variable is method specific?
                                  if param[:type] == '?'
                                    param[:type] = "#{type_var.name}:#{type_application_counter}:#{param[:type]}"
                                  else
                                    param[:type] = "#{type_var.name}:#{param[:type]}:#{type_application_counter}"
                                  end
                                  parse(param, klass)
                                elsif param[:sub_kind] == :method_type_var
                                  # A type parameter that is not bound in the generic type declaration.
                                  # It has to be local to the method
                                  is_generic = true
                                  Types::Polymorphism::TypeVariable.new("#{klass}:#{param[:type]}", :gen_name => false)
                                else
                                  begin
                                    # The Generic type is bound to a concrete type: bound == upper_bound == lower_bound
                                    bound = Types::TySingletonObject.new(Object.const_get(param[:type]))
                                    concrete_param = Types::Polymorphism::TypeVariable.new(type_var.name,
                                                                                           :upper_bound => bound,
                                                                                           :lower_bound => bound,
                                                                                           :gen_name => false)
                                    concrete_param.bind(bound)
                                    concrete_param
                                  rescue NameError => e
                                    # TODO: transform this into the method_type_var shown before
                                    is_generic = true
                                    Types::Polymorphism::TypeVariable.new(param[:type], :gen_name => false)
                                  end
                                end
                              end
            concrete_type_vars << parsed_type_var
          end

          if is_generic
            Types::TyGenericSingletonObject.new(ruby_type, concrete_type_vars)
          else
            Types::TyGenericObject.new(ruby_type, concrete_type_vars)
          end
        end

        def type_application_counter
          @type_application_counter ||= 0
          @type_application_counter += 1
        end

        def parse_object_type(type)
          if type == :unit
            Types::TyUnit.new
          else
            ruby_type = Object.const_get(type)
            Types::TyObject.new(ruby_type)
          end
        rescue StandardError => e
          TypedRb.log(binding, :error, "Error parsing object from type #{type}, #{e.message}")
          fail TypeParsingError, "Unknown Ruby type #{type}"
        end

        def parse_existential_object_type(type)
          ruby_type = Object.const_get(type)
          BasicObject::TypeRegistry.find_existential_type(ruby_type)
        rescue StandardError => e
          TypedRb.log(binding, :error, "Error parsing existential object from type #{type}, #{e.message}")
          raise TypeParsingError, "Unknown Ruby type #{type}"
        end

        def parse_singleton_object_type(type, node=nil)
          ruby_type = Object.const_get(type)
          generic_type = BasicObject::TypeRegistry.find_generic_type(ruby_type)
          if generic_type
            generic_type.node = node
            generic_type
          else
            Types::TySingletonObject.new(ruby_type, node)
          end
        rescue StandardError => e
          TypedRb.log(binding, :error, "Error parsing singleton object from type #{type}, #{e.message}")
          raise TypeParsingError, "Unknown Ruby type #{type}"
        end

        def parse_function_type(arg_types, klass)
          return_type = parse(arg_types.pop, klass)
          block_type = if arg_types.last.is_a?(Hash) && arg_types.last[:kind] == :block_arg
                         block_type = arg_types.pop
                         parse_function_type(block_type[:block], klass)
                       else
                         nil
                       end
          arg_types = arg_types.map{ |arg| parse(arg, klass) }
          is_generic = (arg_types + [return_type]).any? { |var| var.is_a?(Types::TyGenericSingletonObject) ||
                                                          var.is_a?(Types::Polymorphism::TypeVariable) }

          is_generic = is_generic || block_type.generic? if block_type

          function_class = is_generic ? Types::TyGenericFunction : Types::TyFunction
          function_type = function_class.new(arg_types, return_type)
          function_type.local_typing_context = Types::TypingContext.empty_typing_context if function_type.generic?
          function_type.with_block_type(block_type) if block_type
          function_type
        end
      end
    end
  end
end
