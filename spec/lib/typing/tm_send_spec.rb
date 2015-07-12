require_relative '../../spec_helper'

#TODO: parsing function will return a symbol, not the function
# some of this specs expectations need to change
describe TypedRb::Model::TmSend do
  let(:language) { TypedRb::Language.new }

  context 'with functions receiving function' do
    it 'is possible to pass lambda functions as arguments' do
      expr = <<__END
      ts '#t / (String -> Integer) -> Integer'
      def t(f)
        f['test']
      end

      f = ->(s) { 0 }

      t(f)
__END

      result = language.check(expr)
      expect(result).to eq(tyinteger)
    end

    it 'respects contravariance in the input type' do

      classes = <<__END
      class Animal
        ts '#initialize / -> unit'

        ts '#animal / -> unit'
        def animal; end
      end

      class Mammal < Animal
        ts '#initialize / -> unit'

        ts '#mammal / -> unit'
        def mammal; end
      end

      class Cat < Mammal
        ts '#initialize / -> unit'

        ts '#cat / -> unit'
        def cat; end
      end
__END

      expr = <<__END
      #{classes}

      ts '#t / (Mammal -> Integer) -> Integer'
      def t(f)
        f[Mammal.new]
      end

      f = ->(s=Mammal.new) { 0 }

      t(f)
__END

      result = language.check(expr)
      expect(result).to eq(tyinteger)

      expr = <<__END
      #{classes}

      ts '#t / (Mammal -> Integer) -> Integer'
      def t(f)
        f[Mammal.new]
      end

      f = ->(s=Animal.new) { 0 }

      t(f)
__END

      result = language.check(expr)
      expect(result).to eq(tyinteger)

      expr = <<__END
      #{classes}

      ts '#t / (Mammal -> Integer) -> Integer'
      def t(f)
        f[Mammal.new]
      end

      f = ->(s=Cat.new) { s.cat }

      t(f)
__END
      expect {
        result = language.check(expr)
        #cat undefined for Mammal,
        # s => cat s :gt Cat, s :gt Mammal
      }.to raise_error(StandardError)


      expr = <<__END
      #{classes}

      ts '#mammal_to_i / (Mammal -> Integer) -> Integer'
      def mammal_to_i(mammalf)
        mammalf[Mammal.new]
      end

      ts '#cat_to_i / (Cat -> Integer) -> Integer'
      def cat_to_i(catf)
        mammal_to_i(catf)
      end
__END
      expect {
        result = language.check(expr)
        # Cat not >= Mammal
      }.to raise_error(StandardError)

      expr = <<__END
      #{classes}

      ts '#mammal_to_i / (Mammal -> Integer) -> Integer'
      def mammal_to_i(mammalf)
        mammalf[Mammal.new]
      end

      ts '#animal_to_i / (Animal -> Integer) -> Integer'
      def animal_to_i(animalf)
        mammal_to_i(animalf)
      end
__END
      result = language.check(expr)
      expect(result.to_s).to eq('((Animal -> Integer) -> Integer)')
    end

    it 'respects covariance in the output type' do

      classes = <<__END
      class Animal
        ts '#initialize / -> unit'

        ts '#animal / -> unit'
        def animal; end
      end

      class Mammal < Animal
        ts '#initialize / -> unit'

        ts '#mammal / -> unit'
        def mammal; end
      end

      class Cat < Mammal
        ts '#initialize / -> unit'

        ts '#cat / -> unit'
        def cat; end
      end
__END

      expr = <<__END
      #{classes}

      ts '#integer_to_mammal / (Integer -> Mammal) -> Mammal'
      def integer_to_mammal(mammalf)
        mammalf[1]
      end

      ts '#integer_to_animal / (Integer -> Animal) -> Mammal'
      def integer_to_animal(animalf)
        integer_to_mammal(animalf)
      end
__END
      expect do
        result  = language.check(expr)
      end.to raise_error(StandardError)


      expr = <<__END
      #{classes}

      ts '#integer_to_mammal / (Integer -> Mammal) -> Mammal'
      def integer_to_mammal(mammalf)
        mammalf[1]
      end

      ts '#integer_to_cat / (Integer -> Cat) -> Mammal'
      def integer_to_cat(catf)
        integer_to_mammal(catf)
      end
__END

      result  = language.check(expr)
      expect(result.to_s).to eq('((Integer -> Cat) -> Mammal)')
    end
  end
end
