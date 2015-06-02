require_relative '../../../../spec_helper'

describe TypedRb::Languages::FeatherweightRuby::Model::TmFun do

  let(:code) do
    $TYPECHECK = true
    code =<<__CODE
      class A
        ts '#func / Integer -> String'
        def func(num)
          'string'
        end
      end
__CODE

    eval(code)

    ::BasicObject::TypeRegistry.normalize_types!
  end

  it 'should be possible to type check a function' do

  end

end