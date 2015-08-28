module TypedRb
  module TypeSignature
    class ParsingError < StandardError
      def initialize(expr, reason)
        super "Error parsing type signature '#{expr}': #{reason}"
      end
    end

    module TokenProcessor
      def group_tokens(tokens)
        next_group = []
        groups = [next_group]
        tokens.each do |token|
          if token == :<
            next_group = []
            groups << next_group
          else
            next_group << token
          end
        end
        groups
      end

      def transform_function_tokens(tokens)
        group_tokens(tokens).map do |token_group|
          if token_group.is_a?(Array)
            transform_nested_function(token_group)
          elsif token_group.is_a?(String)
            token_group
          end
        end.compact
      end

      def variable_group?(token_group)
        token_group.drop(1).all? do |token|
          token.is_a?(Hash) &&
            (token[:kind] == :type_var ||
             token[:kind] == :generic_type)
        end
      end

      def transform_nested_function(token_group)
        if token_group.size > 1 &&
           variable_group?(token_group) &&
           token_group[0].is_a?(String)
          { :type       => token_group.first,
            :parameters => token_group.drop(1),
            :kind       => :generic_type }
        else
          token_group.first
        end
      end
    end

    module TypeProcessor
      def parse_start_of_type
        new_type = parse_new_type
        @current_function << new_type unless @current_type.empty?
        @stack << @current_function
        @current_type = []
        @current_function = []
      end

      def parse_end_of_function
        new_type = parse_new_type
        @current_function << new_type unless @current_type.empty?
        parent_function = @stack.pop
        next_function_elem = transform_function_tokens(@current_function)
        parent_function << next_function_elem
        parse_block_arg(parent_function) if block_arg?(parent_function)
        @current_function = parent_function
        @current_type = []
      end

      def block_arg?(function_tokens)
        function_tokens[-2] == '&'
      end

      def parse_block_arg(function_tokens)
        block = { :block => function_tokens.pop,
                  :kind  => :block_arg }
        function_tokens.pop
        function_tokens << block
      end

      def parse_binding
        new_type = parse_new_type
        @current_function << new_type unless @current_type.empty?
        @current_type = []
      end

      def parse_end_of_binding
        bound = parse_variable_binding
        # method variables
        if bound[:kind] == :type_var && method_info[bound[:type]]
          bound = method_info[bound[:type]].dup
          bound[:sub_kind] = :method_type_var
        end
        @binding = nil
        parent_function = @stack.pop
        parent_function << bound
        @current_function = parent_function
        @current_type = []
      end

      def parse_variable_binding
        new_type = parse_new_type
        @current_function << new_type unless @current_type.empty?
        if @current_function.size == 1
          { :type => @current_function.first,
            :kind => :type_var }
        else
          if @binding.nil?
            # This is the case for nested generic types
            { :type       => @current_function.first,
              :parameters => @current_function.drop(1),
              :kind       => :generic_type }
          else
            { :type    => @current_function.first,
              :bound   => @current_function.last,
              :binding => @binding,
              :kind    => :type_var }
          end
        end
      end

      def parse_next_elem
        return parse_binding if @in_binding

        new_type = parse_new_type
        @current_function << new_type unless @current_type.empty?
        @current_function << :<
        @current_type = []
      end

      def parse_new_type
        new_type = @current_type.join
        new_type = :unit if new_type == 'unit'
        if new_type.to_s.end_with?('...')
          new_type = new_type.split('...').first
          new_type = @current_function.pop if new_type.nil?
          new_type =  { :type       => 'Array',
                        :kind       => :rest,
                        :parameters => [new_type] }
        end
        new_type
      end
    end

    class Parser
      include TokenProcessor
      include TypeProcessor

      def self.parse(expr, method_info = {})
        (@parser || Parser.new(method_info)).parse(expr)
      end

      attr_reader :method_info

      def initialize(method_info = {})
        @method_info = method_info
        @current_type = []
        @current_function = []
        @stack = []
        @in_binding = false
      end

      def parse(expr)
        expr = sanitize_input(expr)
        expr.each_char { |elem| parse_next_char(elem) }
        build_final_signature
      end

      private

      def sanitize_input(expr)
        expr.gsub(/\s+/, '').gsub('->', '/')
      end

      PARSERS = {
        '(' => ->(parser) { parser.parse_start_of_type },
        '[' => ->(parser) { parser.parse_start_of_type },
        ')' => ->(parser) { parser.parse_end_of_function },
        '<' => ->(parser) { parser.parse_binding },
        '>' => ->(parser) { parser.parse_binding },
        ']' => ->(parser) { parser.parse_end_of_binding },
        '/' => ->(parser) { parser.parse_next_elem }
      }

      def parse_next_char(elem)
        setup_binding_context(elem)
        if PARSERS[elem]
          PARSERS[elem][self]
        else
          @current_type << elem
        end
      end

      def setup_binding_context(elem)
        @in_binding = true  if elem == '['
        @in_binding = false if elem == ']'
        @binding = elem     if elem == '<' || elem == '>'
      end

      def build_final_signature
        fail ParsingError.new(expr, 'Unbalanced parentheses.') unless @stack.empty?

        new_type = parse_new_type

        @current_function << new_type unless @current_type.empty?
        @current_type = []
        final_function = transform_function_tokens(@current_function)

        # Distinguis between function without arguments:
        #   -> unit => [:<, 'unit']
        # and generic type without function (e.g. in the
        # type parameter of a class Array.('Array[Integer]'))
        #   Array[Integer] => ['Array', {:type ... }]
        if @current_function.at(0) != :< && final_function.size == 1
          final_function.last
        else
          final_function
        end
      end
    end
  end
end
