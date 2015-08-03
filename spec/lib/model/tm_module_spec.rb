require_relative '../../spec_helper'

describe TypedRb::Model::TmModule do

  it 'parses ruby modules' do
    code = <<__CODE
        module TMod1
           ts '#x / -> unit'
           def x; 'test'; end
        end
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.is_a?(TypedRb::Types::TyExistentialType)).to eq(true)
    expect(parsed.ruby_type).to eq(TMod1)
  end

  it 'parses nested modules' do
    code = <<__CODE
        module TMod1
          module TMod2
           module TMod3
             module TMod4
               class TMod4C1
                 ts '#x / -> Integer'
                 def x
                   0
                 end
               end
             end
           end
           class TMod4C2; end
          end
        end

       TMod1::TMod2::TMod3::TMod4::TMod4C1.new.x
__CODE

    parsed = TypedRb::Language.new.check(code)
    expect(parsed.ruby_type).to eq(Integer)
  end
end
