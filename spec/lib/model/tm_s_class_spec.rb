require_relative '../../spec_helper'

describe TypedRb::Model::TmSClass do

  it 'parses a singleton class' do
    code = <<__CODE
       ts 'type Pod1[X<Numeric]'
       class Pod1

         ts '.put / [X] -> unit'
         def self.put(n)
           @value = n
         end

         class << self
           ts '.take / -> [X]'
           def take
             @value
           end
         end
       end
__CODE

    TypedRb::Language.new.check(code)
    expect(BasicObject::TypeRegistry.send(:registry)[[:class,Pod1]].keys).to eq(['put', 'take'])
  end
end
