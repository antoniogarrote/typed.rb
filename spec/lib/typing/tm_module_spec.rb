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
          self.return_string
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
                     'Cannot compare types Integer <=> String')
  end
end
