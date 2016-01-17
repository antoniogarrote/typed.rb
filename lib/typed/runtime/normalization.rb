require_relative '../runtime'

module TypedRb
  module Runtime
    module Normalization
      include Validations
      ts '#normalize_generic_types! / -> unit'
      def normalize_generic_types!
        initial_value = @generic_types_registry || Hash.call(Class, TypedRb::Types::TyGenericSingletonObject).new
        @generic_types_registry = generic_types_parser_registry.each_with_object(initial_value) do |type_info, acc|
          generic_singleton_object = build_generic_singleton_object(type_info)
          acc[generic_singleton_object.ruby_type] = generic_singleton_object
        end
        generic_types_parser_registry.each do |type_info|
          check_generic_super_type(type_info)
        end
      end

      ts '#normalize_methods! / -> unit'
      def normalize_methods!
        @registry = @registry || {}
        parser_registry.each_pair do |object_key, method_signatures|
          method_type, class_name = parse_object_key(object_key)
          klass = parse_class(class_name)
          @registry[[method_type, klass]] = normalize_method_signatures(method_signatures, klass, method_type)
        end
      end

      ts '#check_super_type_annotations / -> unit'
      def check_super_type_annotations
        @generic_types_registry.values.each do |type|
          type.super_type.self_materialize if type.super_type
        end
      end

      def build_generic_singleton_object(type_info)
        type_class, info = type_info
        TypedRb.log(binding, :debug,  "Normalising generic type: #{type_class}")
        info[:type] = Class.for_name(type_class)
        info[:parameters] = info[:parameters].map do |parameter|
          ::TypedRb::Runtime::TypeParser.parse(parameter, info[:type])
        end
        ::TypedRb::Types::TyGenericSingletonObject.new(info[:type], info[:parameters])
      end

      def check_generic_super_type(type_info)
        _, info = type_info
        super_type = build_generic_super_type(info)
        @generic_types_registry[info[:type]].super_type = super_type if super_type
      end

      def build_generic_super_type(info)
        with_super_type = valid_super_type?(info[:type], info[:super_type])
        if with_super_type
          TypedRb.log(binding, :debug,  "Normalising generic super type: #{info[:super_type][:type]} for #{info[:type]}")
          build_generic_singleton_object([info[:super_type][:type], info[:super_type]])
        end
      end

      def valid_super_type?(base_class, super_type_info)
        return false if super_type_info.nil?
        valid = base_class.ancestors.map(&:name).detect { |klass_name| klass_name == super_type_info[:type].to_s }
        return true if valid
        fail ::TypedRb::Types::TypeParsingError,
             "Super type annotation '#{super_type_info[:type]}' not a super class of '#{base_class}'"
      end

      def parse_class(class_name)
        return :main if class_name == :main
        Class.for_name(class_name.to_s)
      end

      def find_methods(klass)
        return find_methods_for_top_level_object if klass == :main
        find_methods_for_class(klass)
      end

      def collect_methods(object, options)
        messages = if options[:instance]
                     [:public_instance_methods, :protected_instance_methods, :private_instance_methods]
                   else
                     [:public_methods, :protected_methods, :private_methods]
                   end
        messages.inject([]) do |acc, message|
          acc + object.send(message)
        end
      end

      def find_methods_for_top_level_object
        all_instance_methods = collect_methods(TOPLEVEL_BINDING, instance: false)
        all_methods = collect_methods(TOPLEVEL_BINDING.receiver.class, instance: false)
        build_class_methods_info(:main, all_instance_methods, all_methods)
      end

      def find_methods_for_class(klass)
        all_instance_methods = collect_methods(klass, instance: true)
        all_methods = collect_methods(klass, instance: false)
        build_class_methods_info(klass, all_instance_methods, all_methods)
      end

      def build_class_methods_info(klass, all_instance_methods, all_methods)
        {
          :class            => klass,
          :instance_methods => all_instance_methods,
          :all_methods      => all_methods
        }
      end

      ts '#normalize_signature! / Class -> String -> TypedRb::Types::TyFunction'
      def normalize_signature!(klass, type)
        normalized_signature = ::TypedRb::Runtime::TypeParser.parse(type, klass)
        ::TypedRb::Model::TmFun.with_fresh_bindings(klass, normalized_signature)
      end

      def normalize_method_signatures(method_signatures, klass, method_type)
        method_signatures.each_with_object({}) do |method_info, signatures_acc|
          method, signatures = method_info
          validate_method(find_methods(klass), klass, method, method_type)
          normalized_signatures = signatures.map do |signature|
            validate_function_signature(klass, method, signature, method_type)
            normalized_method = normalize_signature!(klass, signature)
            validate_signature(method_type, normalized_method)
            compute_parameters_info(method_type, klass, method, normalized_method, signature)
            normalized_method
          end
          if method_type == :instance_variable || method_type == :class_variable
            # TODO: print a warning if the declaration of the variable is duplicated
            signatures_acc[method] = normalized_signatures.first
          else
            validate_signatures(normalized_signatures, klass, method)
            signatures_acc[method] = normalized_signatures.sort { |fa, fb| fa.arity <=> fb.arity }
          end
        end
      end

      def compute_parameters_info(method_type, klass, method, normalized_method, signature)
        return if method_type == :instance_variable || method_type == :class_variable
        ruby_params = if method_type == :instance
                        if klass == :main
                          TOPLEVEL_BINDING.receiver.method(method).parameters
                        else
                          klass.instance_method(method).parameters
                        end
                      else
                        if klass == :main
                          TOPLEVEL_BINDING.receiver.class.method(method).parameters
                        else
                          klass.method(method).parameters
                        end
                      end
        ruby_params_clean = ruby_params.reject { |(kind, _)| kind == :block }
        min, max = ruby_params_clean.each_with_object([0, 0]) do |(kind, _), acc|
          acc[1] += 1
          acc[1] = Float::INFINITY if kind == :rest
          acc[0] += 1 if kind == :req
        end

        signature_clean = signature.reject { |acc| acc.is_a?(Hash) && acc[:kind] == :block_arg }
        if signature_clean.count < min || signature_clean.count > max
          fail ::TypedRb::Types::TypeParsingError,
               "Type signature declaration for method '#{klass}.#{method}': '#{signature_clean}' inconsistent with method parameters #{ruby_params.inspect}"
        end

        count = 0
        parameters_info = signature_clean.map do |signature_value|
          type, name = if count > ruby_params_clean.count
                         ruby_params_clean.last
                       else
                         ruby_params_clean[count]
                       end
          count += 1

          if signature_value.is_a?(Hash) && signature_value[:kind] == :rest
            [:rest, name]
          elsif type == :rest
            [:opt, name]
          else
            [type, name]
          end
        end

        normalized_method.parameters_info = parameters_info
      end

      ts '#object_key / String -> String -> String'
      def object_key(kind, receiver)
        "#{kind}|#{receiver}"
      end

      ts '#parse_object_key / String -> Symbol'
      def parse_object_key(object_key)
        object_key.split('|').map(&:to_sym)
      end
    end
  end
end
