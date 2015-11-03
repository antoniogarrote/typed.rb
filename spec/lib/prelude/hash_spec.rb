require_relative '../../spec_helper'

describe Hash do
  let(:language) { TypedRb::Language.new }

  describe '#initialize' do
    it 'type checks / -> Hash[S][T]' do
      result = language.check('Hash.(String,Integer).new')
      expect(result.to_s).to eq('Hash[String][Integer]')
    end

    it 'type checks / -> Hash[S][T] with a literal type annotation' do
      result = language.check("Hash.('[String][Integer]').new")
      expect(result.to_s).to eq('Hash[String][Integer]')
    end

    it 'type checks / -> [T] -> Hash[S][T]' do
      result = language.check("Hash.(String,Integer).new(1)")
      expect(result.to_s).to eq('Hash[String][Integer]')

      expect {
        language.check("Hash.(String,Integer).new('string')")
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end

    it 'type checks / &(Hash[S][T] -> [S] -> unit) -> Hash[S][T]' do
      result = language.check("Hash.(String,Integer).new { |acc,k| acc[k] = 0 }")
      expect(result.to_s).to eq('Hash[String][Integer]')

      expect {
        language.check("Hash.(String,Integer).new { |acc,k| acc[k] = 'string'}")
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  describe '#any?' do
    it 'type checks / &(T -> S -> Boolean) -> Boolean' do
      code = <<__CODE

         ts "#randomBool / String -> Integer -> Boolean"
         def randomBool(s,i); true; end

         Hash.(String,Integer).new.any? { |s,t| randomBool(s,t) }
__CODE

      result = language.check(code)
      expect(result.to_s).to eq('Boolean')

      expect {
        code = <<__CODE

         ts "#randomBool / String -> Integer -> Boolean"
         def randomBool(s,i); true; end

         Hash.(String,Integer).new.any? { |s,t| randomBool(t,s) }
__CODE

        language.check("Hash.(String,Integer).new { |acc,k| acc[k] = 'string'}")
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  describe '#assoc' do
    it 'type checks / [S] -> Pair[S][T]' do
      code = <<__CODE
         h = Hash.(String,Integer).new
         h['key'] = 0
         result = h.assoc('key')
         result.second
__CODE

      result = language.check(code)
      expect(result.to_s).to eq('Integer')

       expect {
         code = <<__CODE
          Hash.(String,Integer).new.assoc(2)
__CODE

         language.check("Hash.(String,Integer).new { |acc,k| acc[k] = 'string'}")
       }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  # describe '#default_proc' do
  #   xit 'type checks / -> (Hash[S][T] -> [S] -> [T])' do
  #     code = 'Hash.(String,Integer).new.default_proc'
  #     #result = language.check(code)
  #   end
  # end

  describe '#delete' do
    it 'type checks / [S] -> [T]' do
      code = <<__CODE
        Hash.(String,Integer).new.delete('str')
__CODE
      result = language.check(code)
      expect(result.ruby_type).to eq(Integer)

      expect {
        language.check('Hash.(String,Integer).new.delete(1)')
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end

    it 'type checks / [S] -> &([S] -> [T]) -> [T]' do
      code = <<__CODE
        Hash.(String,Integer).new.delete('str') { |k| 0 }
__CODE
      result = language.check(code)
      expect(result.ruby_type).to eq(Integer)

      expect {
        code = <<__CODE
        Hash.(String,Integer).new.delete('str') { |k| k }
__CODE
        language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  describe '#delete_if' do
    it 'type checks / [S] -> &([S] -> [T] -> Boolean) -> [T]' do
      code = <<__CODE
        ts '#str_int_bool / String -> Integer -> Boolean'
        def str_int_bool(s,i); true; end
        Hash.(String,Integer).new.delete_if { |k,v| str_int_bool(k,v) }
__CODE
      result = language.check(code)
      expect(result.to_s).to eq('Hash[String][Integer]')

      expect {
        code = <<__CODE
        ts '#str_int_bool / String -> Integer -> Boolean'
        def str_int_bool(s,i); true; end
        Hash.(String,Integer).new.delete_if { |k,v| str_int_bool(v,k) }
__CODE

        language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  describe '#each' do
    it 'type checks / &([S] -> [T] -> unit) -> Hash[S][T]' do
      code = <<__CODE
        ts '#str_int_bool / String -> Integer -> Boolean'
        def str_int_bool(s,i); true; end

        Hash.(String,Integer).new.each { |s,t| str_int_bool(s,t) }
__CODE

      result = language.check(code)
      expect(result.to_s).to eq('Hash[String][Integer]')


      code = <<__CODE
        ts '#str_int_bool / String -> Integer -> Boolean'
        def str_int_bool(s,i); true; end

        Hash.(String,Integer).new.each { |(s,t)| str_int_bool(s,t) }
__CODE

      result = language.check(code)
      expect(result.to_s).to eq('Hash[String][Integer]')

      expect {
        code = <<__CODE
        ts '#str_int_bool / String -> Integer -> Boolean'
        def str_int_bool(s,i); true; end
        Hash.(String,Integer).new.delete_if { |k,v| str_int_bool(v,v) }
__CODE

        language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)

      expect {
        code = <<__CODE
        ts '#str_int_bool / String -> Integer -> Boolean'
        def str_int_bool(s,i); true; end
        Hash.(String,Integer).new.delete_if { |(k,v)| str_int_bool(v,v) }
__CODE

        language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  describe '#each_key' do
    it 'type checks / -> Enumerator' do
      result = language.check('Hash.(String,Integer).new.each_key')
      expect(result.ruby_type).to eq(Enumerator)
    end

    it 'type checks / &([S] -> unit) -> Hash[S][T]' do
      code = <<__CODE
        ts '#str_bool / String -> Boolean'
        def str_bool(s); true; end

        Hash.(String,Integer).new.each_key { |s| str_bool(s,t) }
__CODE

      result = language.check(code)
      expect(result.to_s).to eq('Hash[String][Integer]')

      expect {
        code = <<__CODE
          ts '#int_bool / Integer -> Boolean'
          def int_bool(s); true; end

          Hash.(String,Integer).new.each_key { |s| int_bool(s) }
__CODE

        language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  describe '#eql?' do
    it 'type checks / Hash[?][?] -> Boolean' do
      result = language.check('Hash.(String,Integer).new.eql?(Hash.(String,String).new)')
      expect(result.to_s).to eq('Boolean')

      result = language.check('Hash.(String,Integer).new.eql?(Array.(String).new)')
      expect(result.to_s).to eq('Boolean')
    end
  end

  describe '#fetch' do
    it 'type checks / [S] -> &([S] -> [T]) -> [T]' do

      code = <<__CODE
        h = Hash.(String,Integer).new
        h['str'] = 0
        h.fetch('str')
__CODE
      result = language.check(code)
      expect(result.ruby_type).to eq(Integer)

      code = <<__CODE
        ts '#str / String -> unit'
        def str(k); end

        h = Hash.(String,Integer).new
        h['str'] = 0
        h.fetch('str') { |k| str(k) }
__CODE
      result = language.check(code)
      expect(result.ruby_type).to eq(Integer)

      expect {
        code = <<__CODE
        h = Hash.(String,Integer).new
        h['str'] = 0
        begin
           h.fetch(0)
        rescue; end
__CODE
        language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)

      expect {
        code = <<__CODE
        ts '#intf / Integer -> unit'
        def intf(k); end

        h = Hash.(String,Integer).new
        h['str'] = 0
        h.fetch('str') { |k| intf(k) }
__CODE
        language.check(code)
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end

    it 'type checks / [S] -> [T] -> [T]' do
      result = language.check('Hash.(String,Integer).new.fetch("str",0)')
      expect(result.ruby_type).to eq(Integer)

      expect {
        language.check('Hash.(String,Integer).new.fetch("str","default")')
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  describe '#invert' do
    it 'type checks / -> Hash[T][S]' do
      result = language.check('Hash.(String,Integer).new.invert')
      expect(result.to_s).to eq('Hash[Integer][String]')
    end
  end

  describe '#merge' do
    it 'type checks / Hash[S][T] -> Hash[S][T]' do
      result = language.check('a = Hash.(String,Integer).new; Hash.(String,Integer).new.merge(a)')
      expect(result.to_s).to eq('Hash[String][Integer]')

      expect {
        language.check('a = Hash.(Integer,Integer).new; Hash.(String,Integer).new.merge(a)')
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end

    context 'with a given block' do
      it 'type checks / Hash[S][T] -> &([S] -> [T] -> [T] -> [S]) -> Hash[S][T]' do
        code = <<__CODE
               ts '#str_int_int_fn / String -> Integer -> Integer -> Integer'
               def str_int_int_fn(k,v1,v2); v1 + v2; end

               a = Hash.(String,Integer).new
               Hash.(String,Integer).new.merge(a) { |k,v1,v2| str_int_int_fn(k, v1, v2) }
__CODE
        result = language.check(code)
        expect(result.to_s).to eq('Hash[String][Integer]')

        expect {
          code = <<__CODE
               ts '#str_str_int_fn / String -> String -> Integer -> Integer'
               def str_str_int_fn(k,v1,v2); 0; end

               a = Hash.(String,Integer).new
               Hash.(String,Integer).new.merge(a) { |k,v1,v2| str_str_int_fn(k, v1, v2) }
__CODE
          language.check(code)
        }.to raise_error(TypedRb::Types::UncomparableTypes)
      end
    end
  end

  describe '#rassoc' do
    it 'type checks / [T] -> Pair[S][T]' do
      result = language.check('Hash.(String,Integer).new.rassoc(2)')
      expect(result.to_s).to eq('Pair[String][Integer]')
    end
  end

  describe '#shift' do
    it 'type checks / -> Pair[S][T]' do
      result = language.check('Hash.(String,Integer).new.shift')
      expect(result.to_s).to eq('Pair[String][Integer]')
    end
  end

  describe '#to_a' do
    it 'type checks / -> Array[Pair[S][T]]' do
      result = language.check('Hash.(String,Integer).new.to_a')
      expect(result.to_s).to eq('Array[Pair[String][Integer]]')
    end
  end

  describe '#values' do
    it 'type checks / -> Array[S]' do
      result = language.check('Hash.(String,Integer).new.values')
      expect(result.to_s).to eq('Array[Integer]')
    end
  end

  describe '#values_at' do
    it 'type checks / -> Array[S]' do
      result = language.check('Hash.(String,Integer).new.values_at("a","b","d")')
      expect(result.to_s).to eq('Array[Integer]')
    end
  end
end
