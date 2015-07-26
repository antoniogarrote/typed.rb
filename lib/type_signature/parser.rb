module TypedRb
  module TypeSignature
    class ParsingError < StandardError
      def initialize(expr, reason)
        super "Error parsing type signature '#{expr}': #{reason}"
      end
    end

    class Parser

      def self.parse(expr)
        (@parser || Parser.new).parse(expr)
      end

      def initialize
        @current_type = []
        @current_function = []
        @stack = []
        @in_binding = false
      end

      def parse (expr)
        expr = expr.gsub(/\s+/,'').gsub('->','>')

        expr.each_char do |elem|
          if elem == '('
            parse_start_of_type
          elsif elem == '['
            @in_binding  = true
            parse_start_of_type
          elsif elem == ')'
            parse_end_of_function
          elsif elem == '<'
            @binding = '<'
            parse_binding
          elsif elem == ']'
            @in_binding  = false
            parse_end_of_binding
          elsif elem == '>' && @in_binding == false
            parse_next_elem
          elsif elem == '>' && @in_binding == true
            @binding = '>'
            parse_binding
          else
            @current_type << elem
          end
        end

        unless @stack.empty?
          fail ParsingError.new(expr, 'Unbalanced parentheses.')
        end


        new_type = parse_new_type

        @current_function << new_type unless @current_type.empty?
        @current_type = []
        final_function = transform_function_tokens(@current_function)

        # Distinguis between function without arguments:
        #   -> unit => [:<, 'unit']
        # and generic type without function (e.g. in the  type parameter of a class Array.('Array[Integer]'))
        #   Array[Integer] => ['Array', {:type ... }]
        if @current_function.at(0) != :< && final_function.size == 1
          final_function.last
        else
          final_function
        end
      end

      private

      def parse_start_of_type
        new_type = parse_new_type
        @current_function << new_type unless @current_type.empty?
        @stack << @current_function
        @current_type = []
        @current_function = []
      end

      def transform_function_tokens(tokens)
        next_function_elem, last_token = tokens.inject([[],[]]) do |(total,type), token|
            if token == :<
              total << type
              [total, []]
            else
              type << token
              [total,type]
            end
          end
        next_function_elem << last_token
        next_function_elem = next_function_elem.map do |token_group|
          if(token_group.is_a?(Array))
            if (token_group.size > 1 &&
                token_group.drop(1).all? do |token|
                  token.is_a?(Hash) && (token[:kind] == :type_var || token[:kind] == :generic_type)
                end &&
                token_group[0].is_a?(String))
              { :type => token_group.first, :parameters => token_group.drop(1), :kind => :generic_type }
            else
              token_group.first
            end
          elsif(token_group.is_a?(String))
            token_group
          end
        end
        next_function_elem.compact
      end

      def parse_end_of_function
        new_type = parse_new_type

        @current_function << new_type unless @current_type.empty?

        parent_function = @stack.pop
        next_function_elem = transform_function_tokens(@current_function)
        parent_function << next_function_elem
        if parent_function[-2] == '&'
          block = { :block => parent_function.pop, :kind => :block_arg }
          parent_function.pop
          parent_function << block
        end
        @current_function = parent_function
        @current_type = []
      end

      def parse_binding
        new_type = parse_new_type
        @current_function << new_type unless @current_type.empty?
        @current_type = []
      end

      def parse_end_of_binding
        new_type = parse_new_type
        @current_function << new_type unless @current_type.empty?
        bound = if @current_function.size == 1
                  { :type => @current_function.first, :kind => :type_var }
                else
                  if @binding.nil?
                    # This is the case for nested generic types
                    { :type => @current_function.first, :parameters => @current_function.drop(1), :kind => :generic_type }
                  else
                    { :type => @current_function.first, :bound => @current_function.last, :binding => @binding, :kind => :type_var }
                  end
                end
        @binding = nil
        parent_function = @stack.pop
        parent_function << bound
        @current_function = parent_function
        @current_type = []
      end

      def parse_next_elem
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
          if new_type.nil?
            new_type = @current_function.pop
          end
          new_type =  { :type => 'Array', :kind => :rest, :parameters => [new_type] }
        end
        new_type
      end
    end
  end
end
