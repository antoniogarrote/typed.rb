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
      end

      def parse (expr)
        expr = expr.gsub(/\s+/,'').gsub('->','>')
        expr.each_char do |elem|
          if elem == '(' || elem == '['
            parse_start_of_type
          elsif elem == ')'
            parse_end_of_function
          elsif elem == '<'
            parse_binding
          elsif elem == ']'
            parse_end_of_binding
          elsif elem == '>'
            parse_next_elem
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

        if @current_function.size == 1
          @current_function.last
        else
          @current_function = transform_function_tokens(@current_function)
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
            if (token_group.size > 1 && token_group.drop(1).all?{ |token| token.is_a?(Hash) && token[:bound] } && token_group[0].is_a?(String))
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
                  { :type => @current_function.first, :bound => 'BasicObject', :kind => :type_var }
                else
                  { :type => @current_function.first, :bound => @current_function.last, :kind => :type_var }
                end
        parent_function = @stack.pop
        parent_function << bound
        @current_function = parent_function
        @current_type = []
      end

      def parse_next_elem
        # binding.pry
        new_type = parse_new_type
        @current_function << new_type unless @current_type.empty?
        @current_function << :<
        @current_type = []
      end

      def parse_new_type
        new_type = @current_type.join
        new_type = :unit if new_type == 'unit'
        new_type
      end
    end
  end
end
