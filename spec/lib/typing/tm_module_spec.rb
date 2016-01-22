require_relative '../../spec_helper'

describe TypedRb::Model::TmModule do
  let(:language) { TypedRb::Language.new }

  it 'includes a module in a class' do
    code = <<__CODE
       module TMod2
        ts '#x / -> String'
        def x; 'test'; end
       end

       include TMod2
__CODE

    expect do
      language.check(code)
    end.to_not raise_error
  end

  it 'detects errors in the mixed in type' do
    code = <<__CODE
      module TMod3
        ts '#x / -> String'
        def x
          return_string
        end
      end

      class TMod3C1
        include TMod3
        ts '#return_string / -> Integer'
        def return_string; 2; end
      end
__CODE

    expect {
      language.check(code)
    }.to raise_error(TypedRb::Types::UncomparableTypes,
                     /Cannot compare types Integer <=> String/)
  end

  it 'includes a module referencing instance variables in a class' do
    code = <<__CODE
       module TMod4
        ts '#x / Integer -> unit'
        def x(i); @a = i; end
       end

       class TMod4C1
         include TMod4

         ts '#a / -> Integer'
         def a; @a; end
       end

       TMod4C1.new.a
__CODE

    result = language.check(code)
    expect(result.ruby_type).to eq(Integer)
  end

  it 'typechecks the inclusion of a module in multiple classes' do
    code = <<__CODE
       module TMod4
        ts '#x / Integer -> unit'
        def x(i); @a = i; end
       end

       class TMod4C1
         include TMod4

         ts '#a / -> Integer'
         def a; @a; end
       end

       class TMod4C2
         include TMod4
       end

       TMod4C2.new.x(3)
       TMod4C1.new.a
__CODE

    result = language.check(code)
    expect(result.ruby_type).to eq(Integer)
  end
end
