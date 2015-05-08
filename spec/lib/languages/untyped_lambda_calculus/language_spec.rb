# -*- coding: utf-8 -*-
describe TypedRb::Languages::UntypedLambdaCalculus::Language do

  let(:lang) { described_class.new }

  context '#eval' do
    it 'evalutes a \'x\' expression' do
      expect(lang.eval('x').to_s).to be == 'x'
    end

    it 'evalutes a \'->(x){ x }\' expression' do
      expect(lang.eval('->(x){ x }').to_s).to be == 'λx.x'
    end

    it 'evalutes a \'->(x){ x }[y]\' expression' do
      expect(lang.eval('->(x){ x }[y]').to_s).to be == 'y'
    end

    it 'evalutes a \'->(x){ x }[->(m){ ->(z){ m } }[o][p]]\' expression' do
      expr = '->(x){ x }[->(m){ ->(z){ m } }[o][p]]'
      puts "\nEVALUATING:"
      puts lang.parse(expr).to_s(false)
      puts lang.parse(expr).to_s(true)
      puts "-------------------"
      expect(lang.eval(expr).to_s).to be == 'o'
    end

    it 'evaluates the Y combinator \'->(f) { ->(x) { f[x[x]] }[->(z) { f[z[z]]}]}\' expression' do
      expr = '->(f) { ->(x) { f[x[x]] }[->(z) { f[z[z]]}]}[m]'
      puts "\nEVALUATING:"
      puts lang.parse(expr).to_s(false)
      puts lang.parse(expr).to_s(true)
      puts "-------------------"
      puts lang.eval(expr).to_s
    end
  end
end
