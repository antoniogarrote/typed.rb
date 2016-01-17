require_relative '../../spec_helper'

describe 'instance vars' do
  let(:language) { TypedRb::Language.new }

  it 'types correctly instance vars, case 1' do
    code = <<__END
      class TestIVar

        ts '#gm1 / -> Integer'
        def gm1
          @a = 1
        end

        ts '#gm2 / -> String'
        def gm2
          @a = 'hey'
          'hey'
        end

        ts '#gm3 / -> Object'
        def gm3
          @a
        end
      end
__END

    language.check(code)
  end

  it 'types correctly instance vars, positive case 2' do
    code = <<__END
      class TestIVar

        ts '#gm1 / -> Integer'
        def gm1
          @a = 1
        end

        ts '#gm2 / -> String'
        def gm2
          @a = 'hey'
          'hey'
        end

        ts '#gm3 / -> Float'
        def gm3
          @a
        end
      end
__END

    expect {
      language.check(code)
    }.to raise_error(TypedRb::Types::Polymorphism::UnificationError)
  end

  it 'types correctly instance vars, positive case 3' do
    code = <<__END
      class TestIVar

        ts '#gm1 / -> Integer'
        def gm1
          @a = 1
        end

        ts '#gm2 / -> String'
        def gm2
          @a = 'hey'
          'hey'
        end
      end
__END

    expect {
      language.check(code)
    }.not_to raise_error
  end


  it 'types correctly instance vars, positive case 5' do
    code = <<__END
      class TestIVar5
        ts '#gm1 / -> Integer'
        def gm1
          @a = 1
        end
      end

      class TestIVar5
        ts '#gm2 / -> String'
        def gm2
          @a = 'hey'
          @a
        end
      end
__END

    expect {
      language.check(code)
    }.to raise_error
  end
end