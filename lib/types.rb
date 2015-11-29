module TypedRb
  class TypeCheckError < TypeError
    attr_reader :node

    def initialize(msg, node = nil)
      super(build_message_error(msg, node))
      @node = node
    end

    private

    def build_message_error(msg, nodes)
      file = $TYPECHECK_FILE || 'NO FILE'
      if nodes && nodes.is_a?(Array)
        num_columns = (nodes.last.loc.column - 2)
        num_columns = num_columns < 0 ? 0 : num_columns
        "\n  #{msg}\n...\n>>>#{file}:#{nodes.first.loc.line}\n#{'=' * (nodes.first.loc.column - 2)}> #{nodes.first.loc.expression.source}\n\
##{file}:#{nodes.last.loc.line}\n#{'=' * num_columns}> #{nodes.last.loc.expression.source}\n...\n"
      elsif nodes
        line = nodes.loc.line
        num_columns = (nodes.loc.column - 2)
        num_columns = num_columns < 0 ? 0 : num_columns

        "\n>>>#{file}:#{line}\n  #{msg}\n...\n#{'=' * num_columns}> #{nodes.loc.expression.source}\n...\n"
      else
        msg
      end
    end
  end

  module Types
    class TypeParsingError < TypeCheckError; end

    class Type
      attr_accessor :node

      def initialize(node)
        @node = node
      end

      def stack_jump?
        false
      end

      # other_type is a meta-type not a ruby type
      def compatible?(other_type, relation = :lt)
        if other_type.instance_of?(Class)
          self.instance_of?(other_type) || other_type == TyError
        else
          relation = (relation == :lt ? :gt : lt)
          other_type.instance_of?(self.class, relation) || other_type.instance_of?(TyError)
        end
      end
    end
  end
end
