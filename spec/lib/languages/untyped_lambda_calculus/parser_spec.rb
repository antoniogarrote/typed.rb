# -*- coding: utf-8 -*-
require_relative '../../../spec_helper'

describe TypedRb::Languages::UntypedLambdaCalculus::Parser do
  subject { described_class.new }
  context "#parse" do

    it "parses a var term" do
      expect(subject.parse("x").to_s).to be == "x"
    end

    it "parses a lambda expression" do
      expect(subject.parse("->(x){ x }").to_s).to be == "λx.x"
      expect(subject.parse("->(x){ y }").to_s).to be == "λx.y"
      expect(subject.parse("->(y){ ->(x){ z } }").to_s).to be == "λy.λx.z"
    end

    it "parses application of lambda expressions" do
      expect(subject.parse("->(x){ x }[z]").to_s).to be == "(λx.x z)"
      expect(subject.parse("->(x){ x[y] }[z]").to_s).to be == "(λx.(x y) z)"
    end
  end

end
