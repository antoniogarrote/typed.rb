module TypedRb
  # Helper class used to keep an stack of type signatures
  # being parsed.
  class ParsingContext
    def initialize
      @types_stack = []
    end

    def push(type)
      @types_stack << type
    end

    def pop
      @types_stack.pop
    end

    def with_type(type)
      push type
      result = yield
      pop
      result
    end

    def context_name
      @types_stack.last.join('::')
    end

    def path_name
      @types_stack.map { |key| key[1] }.join('::')
    end

    def singleton_class?
      @types_stack.last.first == :self rescue false
    end
  end
end
