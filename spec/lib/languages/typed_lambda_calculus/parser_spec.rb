# -*- coding: utf-8 -*-
require_relative '../../../spec_helper'

describe TypedRb::Languages::TypedLambdaCalculus::Parser do
  subject { described_class.new }
  context '#parse' do

    it 'supports bool terms' do
      expect(subject.parse('true')).to be_instance_of(TypedRb::Languages::TypedLambdaCalculus::Model::TmBoolean)
      expect(subject.parse('false')).to be_instance_of(TypedRb::Languages::TypedLambdaCalculus::Model::TmBoolean)
    end

    it 'supports int terms' do
      expect(subject.parse('4')).to be_instance_of(TypedRb::Languages::TypedLambdaCalculus::Model::TmInt)
    end

    it 'supports float terms' do
      expect(subject.parse('4.34')).to be_instance_of(TypedRb::Languages::TypedLambdaCalculus::Model::TmFloat)
    end

    it 'supports string terms' do
      expect(subject.parse('"a string"')).to be_instance_of(TypedRb::Languages::TypedLambdaCalculus::Model::TmString)
      expect(subject.parse("'a string'")).to be_instance_of(TypedRb::Languages::TypedLambdaCalculus::Model::TmString)
    end

    it 'supports var terms' do
      expect(subject.parse('x').to_s).to be == 'x'
    end

    it 'supports lambda expression' do
      expect(subject.parse("typesig 'Int => Bool'; ->(x){ x }").to_s).to be == 'λx:(Int -> Bool).x'
      expect(subject.parse("typesig 'Int => Bool'; ->(x){ y }").to_s).to be == 'λx:(Int -> Bool).y'
      expect(subject.parse("typesig 'Int => (Bool => Int)'; ->(y){ typesig 'Bool => Int'; ->(x){ z } }").to_s).to be ==
        'λy:(Int -> (Bool -> Int)).λx:(Bool -> Int).z'
    end

    it 'throws an exception if missing type annotation for lambda' do
      expect{
        subject.parse('->(x){ x }').to_s
      }.to raise_error
      expect {
        subject.parse('typesig Int => [Bool => Int]; ->(y){ ->(x){ z } }').to_s
      }.to raise_error
    end

    it 'supports application of lambda expressions' do
      expect(subject.parse("typesig 'Int => Bool'; ->(x){ x }[z]").to_s).to be == '(λx:(Int -> Bool).x z)'
    end
  end

end
