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
          @current_function.first
        else
          @current_function.reject{ |e| e == :< }
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

      def parse_end_of_function
        new_type = parse_new_type
        @current_function << new_type unless @current_type.empty?
        parent_function = @stack.pop
        parent_function << @current_function.reject{ |e| e == :< }
        if parent_function.size > 1 && parent_function[-2] == '&'
          block = {:block => parent_function.pop}
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
                  { :type => @current_function.first, :bound => 'BasicObject' }
                else
                  { :type => @current_function.first, :bound => @current_function.last }
                end
        parent_function = @stack.pop
        parent_function << bound
        @current_function = parent_function
        @current_type = []
      end

      def parse_next_elem
        new_type = parse_new_type
        @current_function << :<
        @current_function << new_type unless @current_type.empty?
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
