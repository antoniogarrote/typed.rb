require_relative '../../../spec_helper'


describe TypedRb::Languages::ArithmeticExpressions::Language do
  let(:lang) { described_class.new }
  context '#eval' do
    it 'evalutes a \'true\' expression' do
      expect(lang.eval('true')).to be_instance_of(TmTrue)
    end
    it 'evaluates a \'false\' expression' do
      expect(lang.eval('false')).to be_instance_of(TmFalse)
    end
    it 'evaluates a \'0\' expression' do
      expect(lang.eval('0')).to be_instance_of(TmZero)
    end
    it 'evaluates a \'succ(expr)\' expression' do
      expect(lang.eval('succ(0)')).to be_instance_of(TmSucc)
    end
    it 'evaluates a \'pred(expr)\' expression' do
      expect(lang.eval('pred(0)')).to be_instance_of(TmZero)
    end
    it 'evaluates a \'pred(expr)\' expression' do
      expect(lang.eval('pred(succ(succ(0)))')).to be_instance_of(TmSucc)
    end
    it 'evaluates a \'isZero(0)\' expression' do
      expect(lang.eval('isZero(0)')).to be_instance_of(TmTrue)
    end
    it 'evaluates a \'isZero(expr)\' expression' do
      expect(lang.eval('isZero(succ(0))')).to be_instance_of(TmFalse)
    end
    it 'evaluates a \'if...then...else...end\' expression' do
      evald = lang.eval('if true; true; else; false; end')
      expect(evald).to be_instance_of(TmTrue)
    end
    it 'evaluates a \'if...then...else...end\' expression' do
      evald = lang.eval('if false; true; else; false; end')
      expect(evald).to be_instance_of(TmFalse)
    end
  end
end
