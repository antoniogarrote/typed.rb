# -*- coding: utf-8 -*-
require_relative '../../../spec_helper'

describe TypedRb::Languages::TypedLambdaCalculus::Parser do
  subject { described_class.new }
  context '#parse' do
    
    def parse(expr)
      TypedRb::Languages::TypedLambdaCalculus::Model::GenSym.reset
      subject.parse(expr)
    end

    it 'supports bool terms' do
      expect(parse('true')).to be_instance_of(TypedRb::Languages::TypedLambdaCalculus::Model::TmBoolean)
      expect(parse('false')).to be_instance_of(TypedRb::Languages::TypedLambdaCalculus::Model::TmBoolean)
    end

    it 'supports int terms' do
      expect(parse('4')).to be_instance_of(TypedRb::Languages::TypedLambdaCalculus::Model::TmInt)
    end

    it 'supports float terms' do
      expect(parse('4.34')).to be_instance_of(TypedRb::Languages::TypedLambdaCalculus::Model::TmFloat)
    end

    it 'supports string terms' do
      expect(parse('"a string"')).to be_instance_of(TypedRb::Languages::TypedLambdaCalculus::Model::TmString)
      expect(parse("'a string'")).to be_instance_of(TypedRb::Languages::TypedLambdaCalculus::Model::TmString)
    end

    it 'supports var terms' do
      expect(parse('x').to_s).to be == 'x'
    end

    it 'supports lambda expression' do
      expect(parse("typesig 'Int => Bool'; ->(x){ x }").to_s).to be == 'λx:(Int -> Bool).x'
      expect(parse("typesig 'Int => Bool'; ->(x){ y }").to_s).to be == 'λx:(Int -> Bool).y'
      expect(parse("typesig 'Int => (Bool => Int)'; ->(y){ typesig 'Bool => Int'; ->(x){ z } }").to_s).to be ==
        'λy:(Int -> (Bool -> Int)).λx:(Bool -> Int).z'
    end

    it 'supports sequencing of expressions' do
      code = <<__END
       (
          typesig 'Int => Int'
          ->(x) { x }
          typesig 'Bool => Bool'
          ->(y) { y }
       )[true]
__END

      result_expr = /\(\(λ:_gs\[\[\d+:Unit.λy:\(Bool -> Bool\).y λ:_gs\[\[\d+:Unit.λx:\(Int -> Int\).x\) False\)/
      expect(parse(code).to_s).to match(result_expr)
    end

    it 'throws an exception if missing type annotation for lambda' do
      expect{
        parse('->(x){ x }').to_s
      }.to raise_error
      expect {
        parse('typesig Int => [Bool => Int]; ->(y){ ->(x){ z } }').to_s
      }.to raise_error
    end

    it 'supports application of lambda expressions' do
      expect(parse("typesig 'Int => Bool'; ->(x){ x }[z]").to_s).to be == '(λx:(Int -> Bool).x z)'
    end

    it 'renames bindings for function arguments' do
      parsed = parse("typesig 'Int => Bool'; ->(x){ typesig 'Int => Int'; ->(x){ x } }")
      expect(parsed.to_s).to be == 'λx[[2:(Int -> Bool).λx:(Int -> Int).x'
    end

    it 'parses let bindings' do
      code = <<__END
        typesig 'Int => Int'
        id_int = ->(x) { x }

        id_int[3]
__END
      expect(parse(code).to_s).to be == '(λ:_gs[[1:Unit.(id_int 3) λ:_gs[[2:Unit.let id_int = λx:(Int -> Int).x)'
    end
  end

end
