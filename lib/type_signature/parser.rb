require 'polyglot'
require 'treetop'

Treetop.load(File.join(File.dirname(__FILE__), 'grammar'))

module TypedRb
  module TypeSignature
    class Parser

      PARSER = TypeSignaturesParser.new

      def self.parse(expr)
        PARSER.parse(expr).ast
      end
    end
  end
end