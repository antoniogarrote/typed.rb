require_relative '../../../spec_helper'

describe TypedRb::Languages::FeatherweightRuby::Parser do
  subject { described_class.new }

  context '#parse' do

    def parse(expr)
      TypedRb::Languages::TypedLambdaCalculus::Model::GenSym.reset
      subject.parse(expr)
    end

    it 'should parse a class statement' do
      parsed = parse('class A < B; 1; end')
      expect(parsed).to be_instance_of(TypedRb::Languages::FeatherweightRuby::Model::TmClass)
      expect(parsed.class_name).to be == 'A'
      expect(parsed.super_class_name).to be == 'B'
      expect(parsed.body).to be_instance_of(TypedRb::Languages::FeatherweightRuby::Model::TmInt)
    end

    it 'should parse classes without explicit superclass' do
      parsed = parse('class A; 1; end')
      expect(parsed).to be_instance_of(TypedRb::Languages::FeatherweightRuby::Model::TmClass)
      expect(parsed.class_name).to be == 'A'
      expect(parsed.super_class_name).to be == 'Object'
    end

    it 'should parse classes with namespaces' do
      parsed = parse('class Ma::Mb::A < Mc::B; 1; end')
      expect(parsed).to be_instance_of(TypedRb::Languages::FeatherweightRuby::Model::TmClass)
      expect(parsed.class_name).to be == 'Ma::Mb::A'
      expect(parsed.super_class_name).to be == 'Mc::B'
    end
  end
end