require_relative '../../spec_helper'

describe Array do
  let(:language) { TypedRb::Language.new }

  context '#initialize' do
    it 'type checks / -> Array[T]' do
      result = language.check('Array.(Integer).new')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Integer)
    end

    it 'type checks / Integer -> Array[T]' do
      result = language.check('Array.(Integer).new(3)')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Integer)
    end

    it 'type checks / Integer -> [T] -> Array[T]' do
      result = language.check('Array.(String).new(3, "start")')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(String)

      expect {
        result = language.check('Array.(String).new(3, 0)')
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context '#[]' do
    it 'type checks / Object -> Object' do
      result = language.check('Array.(Integer).new(10,0)[0]')
      expect(result.ruby_type).to eq(Object)
    end

    it 'type checks / Integer -> Integer - Array[T]' do
      result = language.check('Array.(Integer).new(10,0)[0, 3]')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Integer)
    end
  end

  context '#collect[E]' do
    it 'type checks / &([T] -> [E]) -> Array[E]' do
      result = language.check('Array.(Integer).new(10,0).collect{ |e| e.to_s }')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(String)
    end
  end

  context '#concat' do
    it 'type checks / Array[T] -> Array[T]' do
      result = language.check('Array.(Integer).new(10,0).concat(Array.(Integer).new(10,0))')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Integer)

      expect {
        language.check('Array.(Integer).new(10,0).concat(Array.(String).new(10,"blah"))')
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context '#count' do
    it 'type checks / &([T] -> Boolean) -> Integer' do
      result = language.check('Array.(Integer).new(10,0).count(0)')
      expect(result.ruby_type).to eq(Integer)

      result = language.check('Array.(Integer).new(10,0).count{ |x| x == 0 }')
      expect(result.ruby_type).to eq(Integer)

      expect {
        code = <<__CODE
          ts '#testarrs / String -> Boolean'
          def testarrs(s); true; end

          Array.(Integer).new(10,0).count{ |x| testarrs(x) }
__CODE
        language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context '#eql?' do
    it 'type checks / Array[?] -> Boolean' do
      code = <<__CODE
        as = Array.(Integer).new(10,0)
        bs = Array.(String).new(10,'')

        as.eql?(bs)
__CODE
      result = language.check(code)
      expect(result.ruby_type).to eq(TrueClass)
    end
  end

  context '#flatten' do
    it 'type checks / -> Array[Object]' do
      code =  <<__END
         a1 =  Array.(Integer).new.fill(10,0)
         a2 = Array.(Integer).new.fill(10,1)
         c = Array.('Array[Integer]').new
         c << a1
         c << a2
         c.flatten
__END
      result = language.check(code)
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Object)
    end

    it 'type checks / Integer -> Array[Object]' do
      code =  <<__END
         a1 =  Array.(Integer).new.fill(10,0)
         a2 = Array.(Integer).new.fill(10,1)
         c = Array.('Array[Integer]').new
         c << a1
         c << a2
         c.flatten(2)
__END
      result = language.check(code)
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Object)
    end
  end

  context '#include?' do
    it 'type checks / [T] -> Boolean' do
      code = <<__END
         a = Array.(Integer).new.fill(10,0)

         a.include?(1)
__END
      result = language.check(code)
      expect(result.ruby_type).to eq(TrueClass)

      code = <<__END
         a = Array.(Integer).new.fill(10,0)

         a.include?('a')
__END
      expect {
        language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context '#insert' do
    it 'type checks / Integer -> [T] -> Array[T]' do
      code = <<__END
         a = Array.(Integer).new.fill(10,0)

         a.insert(0, 1)

         a.insert(0, 1, 2, 3)
__END

      result = language.check(code)
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Integer)
    end
  end

  context '#last' do
    it 'type checks / -> [T]' do
      code = <<__END
        a = Array.(Integer).new.fill(10,0)
        a.last
__END
      result = language.check(code)
      expect(result.ruby_type).to eq(Integer)
    end

    it 'type checks / Integer -> Array[T]' do
      code = <<__END
        a = Array.(Integer).new.fill(10,0)
        a.last(5)
__END
      result = language.check(code)
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Integer)
    end
  end

  context '#map[E]' do
    it 'type checks / &([T] -> [E]) -> Array[E]' do
      result = language.check('Array.(Integer).new(10,0).map{ |e| e.to_s }')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(String)
    end
  end

  context '#permutation' do
    it 'type checks / -> Array[Array[T]]' do
      result = language.check('Array.(Integer).new(10,0).permutation')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.type_vars.first.bound.ruby_type).to eq(Integer)
    end
  end

  context '#product' do
    it 'type checks / Array[T]... -> Array[Array[T]]' do
      result = language.check('Array.(Integer).new(10,0).product(Array.(Integer).new(5,1), Array.(Integer).new(5,2))')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.type_vars.first.bound.ruby_type).to eq(Integer)
    end
  end

  context '#push' do

    it 'type checks / [T]... -> Array[T]' do
      result = language.check('Array.(Integer).new.push(1,2,3)')
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Integer)

      expect {
        language.check('Array.(Integer).new.push(1,2.0,3)')
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context '#sort' do
    it 'type checks / &([T] -> [T] -> Integer) -> Array[T]' do
      code = <<__END
        a = Array.(Integer).new.fill(10,0)
        a.sort
__END
      result = language.check(code)
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Integer)

      code = <<__END
        a = Array.(Integer).new.fill(10,0)
        ts '#tcii / Integer -> Integer -> Integer'
        def tcii(a,b); a <=> b; end
        a.sort{ |a,b| tcii(a,b) }
__END
      result = language.check(code)
      expect(result.ruby_type).to eq(Array)
      expect(result.type_vars.first.bound.ruby_type).to eq(Integer)

      code = <<__END
        ts '#tcss / String -> String -> Integer'
        def tcss(a,b); -1; end
        a = Array.(Integer).new.fill(10,0)
        a.sort{ |a,b| tcss(a,b) }
__END

      expect {
        language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context '#to_s' do
    it 'type checks / -> Hash[T][T]' do
      result = language.check('Array.(Integer).new.to_h')
      expect(result.ruby_type).to eq(Hash)
      expect(result.type_vars.map(&:bound).map(&:ruby_type)).to eq([Integer, Integer])
    end
  end
end
