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
      expect(parsed.owner).to be_nil
    end

    it 'should parse definition of functions with optional args' do
      parsed = parse('def f(x, y=2); x; end')
      expect(parsed).to be_instance_of(TypedRb::Languages::FeatherweightRuby::Model::TmFun)
      expect(parsed.name).to be == :f
      expect(parsed.args.size).to be == 2
      expect(parsed.args.first.first).to be == :arg
      expect(parsed.args[1].first).to be == :optarg
      expect(parsed.args[1].last).to be_instance_of(TypedRb::Languages::FeatherweightRuby::Model::TmInt)
      expect(parsed.body.to_s).to be == 'x'
      expect(parsed.owner).to be_nil
    end

    it 'should parse definition of functions with block args' do
      parsed = parse('def f(x, &b); x; end')
      expect(parsed).to be_instance_of(TypedRb::Languages::FeatherweightRuby::Model::TmFun)
      expect(parsed.name).to be == :f
      expect(parsed.args.size).to be == 2
      expect(parsed.args.first.first).to be == :arg
      expect(parsed.args[1].first).to be == :blockarg
      expect(parsed.body.to_s).to be == 'x'
      expect(parsed.owner).to be_nil
    end

    it 'should parse definition of self functions' do
      parsed = parse('def self.f(x); x; end')
      expect(parsed).to be_instance_of(TypedRb::Languages::FeatherweightRuby::Model::TmFun)
      expect(parsed.name).to be == :f
      expect(parsed.args.size).to be == 1
      expect(parsed.args.first.first).to be == :arg
      expect(parsed.owner).to be == :self
    end

    it 'should parse the use of instance variables' do
      parsed = parse('@a')
      expect(parsed).to be_instance_of(TypedRb::Languages::FeatherweightRuby::Model::TmInstanceVar)
      expect(parsed.val).to be == :@a
    end

    it 'should parse instance variable assginations' do
      parsed = parse('@a = 3')
      expect(parsed).to be_instance_of(TypedRb::Languages::FeatherweightRuby::Model::TmInstanceVarAssignment)
      expect(parsed.lvalue).to be_instance_of(TypedRb::Languages::FeatherweightRuby::Model::TmInstanceVar)
      expect(parsed.lvalue.val).to be == :@a
      expect(parsed.rvalue).to be_instance_of(TypedRb::Languages::FeatherweightRuby::Model::TmInt)
    end
  end
end
