require_relative './spec_helper'

include TypedRb::Languages::ArithmeticExpressions::Model

describe TypedRb::Languages::ArithmeticExpressions::Parser do
  let(:parser) { described_class.new }
  context '#parse' do
    it 'parses a \'true\' expression' do
      expect(parser.parse('true')).to be_instance_of(TmTrue)
    end
    it 'parses a \'false\' expression' do
      expect(parser.parse('false')).to be_instance_of(TmFalse)
    end
    it 'parses a \'0\' expression' do
      expect(parser.parse('0')).to be_instance_of(TmZero)
    end
    it 'parses a \'succ(expr)\' expression' do
      expect(parser.parse('succ(0)')).to be_instance_of(TmSucc)
    end
    it 'parses a \'pred(expr)\' expression' do
      expect(parser.parse('pred(0)')).to be_instance_of(TmPred)
    end
    it 'parses a \'isZero(expr)\' expression' do
      expect(parser.parse('isZero(0)')).to be_instance_of(TmIsZero)
    end
    it 'parses a \'if...then...else...end\' expression' do
      parsed = parser.parse('if true; true; else; false; end')
      expect(parsed).to be_instance_of(TmIfElse)
    end
    it 'raises an exceptio for a forbidden integer' do
      expect {
        parser.parse('12')
      }.to raise_error
    end
    it 'raises an exceptio for an unknown function' do
      expect {
        parser.parse('foo(0)')
      }.to raise_error
    end
    it 'raises an exceptio for an unknown expression' do
      expect {
        parser.parse('bar')
      }.to raise_error
    end
  end
end
