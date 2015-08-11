# -*- coding: utf-8 -*-
require_relative('./types')

module TypedRb
  module Model

    class GenSym
      COUNTS = {} unless defined?(COUNTS)

      def self.reset
        COUNTS.clear
      end

      def self.next(x="_gs")
        count = COUNTS[x] || 1
        sym = "#{x}[[#{count}"
        COUNTS[x] = count + 1
        sym
      end

      def self.resolve(gx)
        if gx.index('[[')
          orig, count = gx.split("[[")
          if count == '1'
            orig
          else
            gx
          end
        else
          gx
        end
      end
    end

    class Expr
      attr_reader :line, :col, :type, :node
      def initialize(node, type = nil)
        @node = node
        @line = node.location.line
        @col = node.location.column
        @type = type
      end

      def check_type(_context)
        fail TypeCheckError.new('Type error: Unknown type', node) if @type.nil?
        @type
      end

      def rename(_from_binding, _to_binding)
        self
      end
    end
  end
end

# load term files
Dir[File.join(File.dirname(__FILE__),'typing','*.rb')].each do |term_file|
  load(term_file)
end
