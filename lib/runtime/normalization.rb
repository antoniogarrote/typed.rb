require_relative '../runtime'

module TypedRb
  module Runtime
    module Normalization
      include Validations
      ts '.normalize_generic_types! / -> unit'
      def normalize_generic_types!
        initial_value = Hash.(Class, TypedRb::Types::TyGenericSingletonObject).new
        @generic_types_registry = generic_types_parser_registry.each_with_object(initial_value) do |type_info, acc|
          generic_singleton_object = build_generic_singleton_object(type_info)
          acc[generic_singleton_object.ruby_type] = generic_singleton_object
        end
      end

      ts '.normalize_methods! / -> unit'
      def normalize_methods!
        @registry = {}
        parser_registry.each_pair do |object_key, method_signatures|
          method_type, class_name = parse_object_key(object_key)
          klass = parse_class(class_name)
          @registry[[method_type, klass]] = normalize_method_signatures(method_signatures, klass, method_type)
        end
      end

      def build_generic_singleton_object(type_info)
        type_class, info = type_info
        TypedRb.log(binding, :debug,  "Normalising generic type: #{type_class}")
        info[:type] = Object.const_get(type_class)
        super_type = build_generic_super_type(info)
        info[:parameters] = info[:parameters].map do |parameter|
          ::TypedRb::Types::Type.parse(parameter, info[:type])
        end
        ::TypedRb::Types::TyGenericSingletonObject.new(info[:type], info[:parameters], super_type)
      end

      def build_generic_super_type(info)
        with_super_type = valid_super_type?(info[:type], info[:super_type])
        build_generic_singleton_object([info[:super_type][:type], info[:super_type]]) if with_super_type
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
        Object.const_get(class_name.to_s)
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

      ts '.normalize_signature! / Class -> String -> TypedRb::Types::TyFunction'
      def normalize_signature!(klass, type)
        ::TypedRb::Types::Type.parse(type, klass)
      end

      def normalize_method_signatures(method_signatures, klass, method_type)
        method_signatures.each_with_object({}) do |method_info, signatures_acc|
          method, signature = method_info
          TypedRb.log(binding, :debug, "Normalizing method #{method_type}[#{klass}] :: #{method} / #{signature}")
          validate_method(find_methods(klass), klass, method, method_type)
          signatures_acc[method] = normalize_signature!(klass, signature)
          validate_signature(method_type, signatures_acc[method])
        end
      end

      ts '.object_key / String -> String -> String'
      def object_key(kind, receiver)
        "#{kind}|#{receiver}"
      end

      ts '.parse_object_key / String -> Symbol -> Symbol'
      def parse_object_key(object_key)
        object_key.split('|').map(&:to_sym)
      end
    end
  end
end
