require_relative '../spec_helper'

describe TypedRb::Languages::PolyFeatherweightRuby::Model::TmSend do

  before :each do
    ::BasicObject::TypeRegistry.registry.clear
  end


  it 'should evaluate lambda functions applications' do
    expr = <<__END
     begin
       a = ->(x) { x }
       a[1]
     end
__END

    parsed = parse(expr)
    result = parsed.check_type(top_level_typing_context)
    puts "------------"
    puts result.inspect
  end
end
