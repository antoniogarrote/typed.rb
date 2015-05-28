require_relative '../../../spec_helper'

describe TypedRb::Languages::FeatherweightRuby::Parser do
  subject { described_class.new }

  context '#parse' do

    def parse(expr)
      TypedRb::Languages::FeatherweightRuby::Model::GenSym.reset
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

    it 'should parse definition of functions' do
      parsed = parse('def f(x); x; end')
      expect(parsed).to be_instance_of(TypedRb::Languages::FeatherweightRuby::Model::TmFun)
      expect(parsed.name).to be == :f
      expect(parsed.args.size).to be == 1
      expect(parsed.args.first.first).to be == :arg
      expect(parsed.body.to_s).to be == 'x'
    end

    it 'should parse definition of functions with optional args' do
      parsed = parse('def f(x, y=2); x; end')
      expect(parsed).to be_instance_of(TypedRb::Languages::FeatherweightRuby::Model::TmFun)
      expect(parsed.name).to be == :f
      expect(parsed.args.size).to be == 2
      expect(parsed.args.first.first).to be == :arg
      expect(parsed.args[1].first).to be == :optarg
      expect(parsed.args[1].last).to be_instance_of(TypedRb::Languages::FeatherweightRuby::Types::TyInteger)
      expect(parsed.body.to_s).to be == 'x'
    end

    it 'should parse definition of functions with block args' do
      parsed = parse('def f(x, &b); x; end')
         expect(parsed).to be_instance_of(TypedRb::Languages::FeatherweightRuby::Model::TmFun)
      expect(parsed.name).to be == :f
      expect(parsed.args.size).to be == 2
      expect(parsed.args.first.first).to be == :arg
      expect(parsed.args[1].first).to be == :blockarg
      expect(parsed.body.to_s).to be == 'x'
    end
  end
end