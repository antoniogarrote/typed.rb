require_relative '../spec_helper'

describe TypedRb::Languages::PolyFeatherweightRuby::Model::TmSend do

  before :each do
    ::BasicObject::TypeRegistry.registry.clear
  end


  it 'evaluates lambda functions applications' do
    expr = <<__END
     a = ->(x) { x }
     a[1]
__END

    parsed = parse(expr)
    result = parsed.check_type(top_level_typing_context)
    expect(result).to eq(tyinteger)

    expr = <<__END
     a = ->(x) { x }
     a[1]
     a['string']
__END

    parsed = parse(expr)
    result = parsed.check_type(top_level_typing_context)
    expect(result).to eq(tystring)
  end
end
