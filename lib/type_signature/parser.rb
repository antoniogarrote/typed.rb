require 'polyglot'
require 'treetop'

Treetop.load(File.join(File.dirname(__FILE__), 'grammar'))

module TypedRb
  module TypeSignature
    class Parser

      PARSER = TypeSignaturesParser.new unless defined?(PARSER)

      def self.parse(expr)
        result = PARSER.parse(expr)
        fail "Error parsing type expression '#{expr}'" if result.nil?
        result.ast
      end
    end
  end
end