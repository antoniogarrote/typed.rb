require_relative '../spec_helper'

describe TypedRb::Types::TyObject do
  let(:ty_object) { TypedRb::Types::TyObject.new(Object) }
  let(:ty_numeric) { TypedRb::Types::TyObject.new(Numeric) }
  let(:ty_integer) { TypedRb::Types::TyObject.new(Integer) }
  let(:ty_string) { tyobject(String) }

  it 'is possible to compare TyObjects' do

    expect(ty_object > ty_numeric).to be_truthy
    expect(ty_numeric > ty_integer).to be_truthy
    expect(ty_object > ty_integer).to be_truthy

    expect(ty_object >= ty_numeric).to be_truthy
    expect(ty_object >= ty_object).to be_truthy
    expect(ty_numeric >= ty_integer).to be_truthy
    expect(ty_numeric >= ty_numeric).to be_truthy
    expect(ty_object >= ty_integer).to be_truthy
    expect(ty_object >= ty_object).to be_truthy

    expect(ty_numeric < ty_object).to be_truthy
    expect(ty_integer < ty_numeric).to be_truthy
    expect(ty_integer < ty_object).to be_truthy

    expect{ ty_string < ty_integer }.to raise_error ArgumentError
    expect{ ty_integer < ty_string }.to raise_error ArgumentError
    expect{ ty_string > ty_integer }.to raise_error ArgumentError
    expect{ ty_integer > ty_string }.to raise_error ArgumentError


    expect(ty_numeric <= ty_numeric).to be_truthy
    expect(ty_integer <= ty_integer).to be_truthy
    expect(ty_object <= ty_object).to be_truthy

    expect(ty_numeric >= ty_numeric).to be_truthy
    expect(ty_integer >= ty_integer).to be_truthy
    expect(ty_object >= ty_object).to be_truthy


    expect([ty_numeric, ty_integer, ty_object].sort).to  eq([ty_integer, ty_numeric, ty_object])
  end

  it 'is possible to compare if two objects are compatible' do
    expect(ty_object.compatible?(ty_numeric, :gt)).to be_truthy
    expect(ty_object.compatible?(ty_numeric, :lt)).to be_falsey
    expect(ty_object.compatible?(ty_numeric, :lt)).to be_falsey
    expect(ty_object.compatible?(ty_numeric, :gt)).to be_truthy
  end

  describe '#find_function_type' do
    before :each do
      ::BasicObject::TypeRegistry.clear
    end

    it 'it can find methods in the base and super classes' do
      $TYPECHECK = true
      code = <<__CODE

         class A1
            ts 'A1#a / String -> unit'
            def a(s); puts 'a'; end
         end

         class B1 < A1
            ts 'B1#b / Numeric -> unit'
            def b(n); puts 'a'; end
         end
__CODE

      eval(code)
      ::BasicObject::TypeRegistry.normalize_types!

      ty_b = described_class.new(B1)

      klass, method = ty_b.find_function_type(:a, 1, false)
      expect(method.to_s).to eq('(String -> NilClass)')
      expect(klass).to eq(A1)

      klass, method = ty_b.find_function_type(:b, 1, false)
      expect(method.to_s).to eq('(Numeric -> NilClass)')
      expect(klass).to eq(B1)
    end

    it 'can find methods with functions as arguments' do
      $TYPECHECK = true
      code = <<__CODE

         class A1
            ts '#a / String -> (String -> String) -> unit'
            def a(s,f); f(s); end
         end
__CODE

      eval(code)
      ::BasicObject::TypeRegistry.normalize_types!

      ty_b = described_class.new(B1)

      klass, method = ty_b.find_function_type(:a, 2, false)
      function = method.from[1]
      expect(function).to be_instance_of(TypedRb::Types::TyFunction)
      expect(function.from.size).to eq(1)
      expect(function.from[0]).to eq(ty_string)
      expect(function.to).to eq(ty_string)
      expect(klass).to eq(A1)
    end

    context 'with multiple signatures including block types' do
      it 'find both versions with and without block type' do
        $TYPECHECK = false
        eval 'class A2; def t(x); end; end'
        $TYPECHECK = true
        code = <<__CODE
        class A2
           ts '#t / Integer -> Integer'
           ts '#t / Integer -> &(Integer -> String) -> String'
        end
__CODE

        eval(code)
        ::BasicObject::TypeRegistry.normalize_types!

        ty_b = described_class.new(A2)

        _, method = ty_b.find_function_type(:t, 1, false)
        expect(method.from.count).to eq(1)
        expect(method.block_type).to be_nil
        expect(method.to.ruby_type).to eq(Integer)

        _, method = ty_b.find_function_type(:t, 1, true)
        expect(method.from.count).to eq(1)
        expect(method.block_type).to_not be_nil
        expect(method.to.ruby_type).to eq(String)
      end
    end
  end

  describe('#parse') do
    before :each do
      ::BasicObject::TypeRegistry.clear
    end

    context 'with a generic type' do

      it 'should parse a generic singleton class if it the var is not bound' do
        $TYPECHECK = true
        code = <<__CODE

         ts 'type A2[T]'
         class A2
            ts '#a / [T]... -> unit'
            def a(*xs); end
         end
__CODE

        eval(code)
        ::BasicObject::TypeRegistry.normalize_types!

        result = TypedRb::Runtime::TypeParser.parse({:type       => 'Array',
                                                     :parameters =>  [{:type=>"T", :bound=>"BasicObject", :kind=>:type_var}],
                                                     :kind       => :rest}, A2)
        expect(result).to be_instance_of(TypedRb::Types::TyGenericSingletonObject)
        expect(result.type_vars[0].bound).to be_nil

        result = TypedRb::Runtime::TypeParser.parse({:type       => 'Array',
                                                     :parameters =>  ['Integer'],
                                                     :kind       => :rest}, A2)
        expect(result).to be_instance_of(TypedRb::Types::TyGenericObject)
        expect(result.type_vars[0].bound.ruby_type).to eq(Integer)
      end
    end
  end
end
