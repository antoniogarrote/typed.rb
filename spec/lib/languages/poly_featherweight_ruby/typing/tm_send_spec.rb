require_relative '../spec_helper'

describe TypedRb::Languages::PolyFeatherweightRuby::Model::TmSend do
  let(:language) { TypedRb::Languages::PolyFeatherweightRuby::Language.new }

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
      }.to raise_error


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
      }.to raise_error

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
  end
end
