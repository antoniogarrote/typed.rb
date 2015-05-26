# -*- coding: utf-8 -*-
require_relative '../../../spec_helper'

describe TypedRb::Languages::SimplyTypedLambdaCalculus::Parser do
  subject { described_class.new }
  context '#parse' do

    it 'a var term' do
      expect(subject.parse('x').to_s).to be == 'x'
    end

    it 'a lambda expression' do
      expect(subject.parse("typesig 'Int -> Bool'; ->(x){ x }").to_s).to be == 'λx:(Int -> Bool).x'
      expect(subject.parse("typesig 'Int -> Bool'; ->(x){ y }").to_s).to be == 'λx:(Int -> Bool).y'
      expect(subject.parse("typesig 'Int -> (Bool -> Int)'; ->(y){ typesig 'Bool -> Int'; ->(x){ z } }").to_s).to be ==
        'λy:(Int -> (Bool -> Int)).λx:(Bool -> Int).z'
    end

    it 'throws an exception if missing type annotation for lambda' do
      expect{
        subject.parse('->(x){ x }').to_s
      }.to raise_error
      expect {
        subject.parse('typesig \'Int -> [Bool -> Int]\'; ->(y){ ->(x){ z } }').to_s
      }.to raise_error
    end

    it 'an application of lambda expressions' do
      expect(subject.parse("typesig 'Int -> Bool'; ->(x){ x }[z]").to_s).to be == '(λx:(Int -> Bool).x z)'
    end
  end

end
