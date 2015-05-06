require_relative '../spec_helper'

describe TypedRb::ParserModule do
  context '#ast' do
    let(:ruby_code) { 'def f(a,b); a + b; end' }
    let(:parser) { Object.new.extend(described_class) }
    it 'parses ruby code and return an AST structure' do
      parsed = parser.ast(ruby_code)
      expect(parsed).to be_instance_of(Parser::AST::Node)
    end
  end
end
