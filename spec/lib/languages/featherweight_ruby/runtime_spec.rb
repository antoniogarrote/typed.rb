require_relative '../../../spec_helper'

describe BasicObject do

  before :each do
    ::BasicObject::TypeRegistry.registry.clear
  end

  it 'parses typesignatures and store data into the type registry' do
    $TYPECHECK = true
    code = <<__END
    class A

      ts 'A#test / String -> unit'
      def test(msg)
        puts msg
      end

      ts 'A.class_method / Int -> Int'

      ts '#abbrev / String -> String'
      ts '.abbrev / String -> String'
    end

    ts 'B#other_test / Int -> unit'
    ts 'A#other_test / Int -> unit'
__END

    eval(code)

    expect(::BasicObject::TypeRegistry.registry['instance_A']['test']).to eq(['String', :unit])
    expect(::BasicObject::TypeRegistry.registry['class_A']['class_method']).to eq(['Int', 'Int'])
    expect(::BasicObject::TypeRegistry.registry['instance_B']['other_test']).to eq(['Int', :unit])
    expect(::BasicObject::TypeRegistry.registry['instance_A']['other_test']).to eq(['Int', :unit])
    expect(::BasicObject::TypeRegistry.registry['instance_A']['abbrev']).to eq(['String', 'String'])
    expect(::BasicObject::TypeRegistry.registry['class_A']['abbrev']).to eq(['String', 'String'])
  end

  it 'normalizes the parsed types with information about the defined classes' do
    $TYPECHECK = true
    code = <<__END
     class A
       ts '#inc / Integer -> Integer'
       def inc(i)
         i+= 1
         i
       end
     end

     class B
       ts '#consume_a / A -> Integer'
       def consume_a(a)
         0
       end

       ts '#consume_b / unit -> Bool'
       def consume_b
         1
       end
     end
__END

    eval(code)

    ::BasicObject::TypeRegistry.normalize_types!

    expect(::BasicObject::TypeRegistry.registry[[:instance,A]]["inc"]).to eq([Integer, Integer])
    expect(::BasicObject::TypeRegistry.registry[[:instance,B]]["consume_a"]).to eq([A, Integer])
    expect(::BasicObject::TypeRegistry.registry[[:instance,B]]["consume_b"]).to eq([:unit, :bool])
  end
end