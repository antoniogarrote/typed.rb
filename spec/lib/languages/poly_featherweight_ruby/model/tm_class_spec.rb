require_relative '../spec_helper'

describe TypedRb::Languages::PolyFeatherweightRuby::Model::TmClass do

  it 'parses a generic type' do
    code = <<__CODE
       ts 'type Pod[X<Numeric]'
       class Pod

         ts '#put / [X] -> unit'
         def put(n)
           @value = n
         end

         ts '#take / -> [X]'
         def take
           @value
         end
       end

       Pod
__CODE

    parsed = TypedRb::Languages::PolyFeatherweightRuby::Language.new.check(code)

    expect(parsed).to be_instance_of(TypedRb::Languages::PolyFeatherweightRuby::Types::TyGenericSingletonObject)
    binding.pry
    # TODO: CHECKS HERE...
    puts parsed.inspect
  end

end
