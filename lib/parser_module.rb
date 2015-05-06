require 'parser/current'

module TypedRb
  # This module includes functions to build
  # AST for ruby code
  module ParserModule
    # Builds an AST for the provided string containing ruby code
    def ast(ruby_code)
      Parser::CurrentRuby.parse(ruby_code)
    end
  end
end
