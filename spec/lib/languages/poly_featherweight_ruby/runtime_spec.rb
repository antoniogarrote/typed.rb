require_relative './spec_helper'

describe BasicObject do

  before :each do
    ::BasicObject::TypeRegistry.registry.clear
  end

  it 'parses type signatures and store data into the type registry' do
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

    expect(::BasicObject::TypeRegistry.registry['instance|A']['test']).to eq(['String', :unit])
    expect(::BasicObject::TypeRegistry.registry['class|A']['class_method']).to eq(['Int', 'Int'])
    expect(::BasicObject::TypeRegistry.registry['instance|B']['other_test']).to eq(['Int', :unit])
    expect(::BasicObject::TypeRegistry.registry['instance|A']['other_test']).to eq(['Int', :unit])
    expect(::BasicObject::TypeRegistry.registry['instance|A']['abbrev']).to eq(['String', 'String'])
    expect(::BasicObject::TypeRegistry.registry['class|A']['abbrev']).to eq(['String', 'String'])
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

       ts '#consume_b / unit -> Boolean'
       def consume_b
         1
       end
     end
__END

    eval(code)

    ::BasicObject::TypeRegistry.normalize_types!

    expect(::BasicObject::TypeRegistry.registry[[:instance,A]]["inc"].to_s).to eq("(Integer -> Integer)")
    expect(::BasicObject::TypeRegistry.registry[[:instance,B]]["consume_a"].to_s).to eq("(A -> Integer)")
    expect(::BasicObject::TypeRegistry.registry[[:instance,B]]["consume_b"].to_s).to eq("(NilClass -> Boolean)")
  end

  it 'parses field type signatures and store the result in the registry' do
    $TYPECHECK = true
    code = <<__END
     class A
       ts 'A\#@a / Integer'
       attr_accessor :a

       ts '#inc / Integer -> Integer'
       def inc(i)
         @a = i+ 1
         @a
       end
     end
__END

    eval(code)


    expect(::BasicObject::TypeRegistry.registry['instance_variable|A']['@a']).to eq('Integer')
  end

  it 'normalizes types signatures for fields and store the result in the registry' do
    $TYPECHECK = true
    code = <<__END
     class A
       ts 'A\#@a / Integer'
       attr_accessor :a

       ts '#inc / Integer -> Integer'
       def inc(i)
         @a = i+ 1
         @a
       end
     end
__END

    eval(code)

    ::BasicObject::TypeRegistry.normalize_types!

    expect(::BasicObject::TypeRegistry.registry[[:instance_variable,A]]["@a"].to_s).to eq('Integer')
  end

  it 'parses type function with multiple arguments' do
    $TYPECHECK = true
    code = <<__END
     class A
       ts '#func / Integer -> Integer -> Integer -> Integer'
       def func(i,j,k)
         i + j + k
       end
     end
__END

    eval(code)

    ::BasicObject::TypeRegistry.normalize_types!

    expect(::BasicObject::TypeRegistry.registry[[:instance,A]]["func"].to_s).to eq('(Integer,Integer,Integer -> Integer)')
  end


  it 'parses type function with multiple arguments' do
    $TYPECHECK = true
    code = <<__END
     class A
       ts '#func / Integer -> (Integer -> Integer -> Integer) -> Integer'
       def func(i)
         yield i, i
       end
     end
__END

    eval(code)

    ::BasicObject::TypeRegistry.normalize_types!

    expect(::BasicObject::TypeRegistry.registry[[:instance,A]]["func"].to_s).to eq('(Integer,(Integer,Integer -> Integer) -> Integer)')
  end

  it 'parses type functions with no arguments' do
    $TYPECHECK = true
    code = <<__END
     class A
       ts '#func / -> Integer'
       def func(i)
         1
       end
     end
__END

    eval(code)

    ::BasicObject::TypeRegistry.normalize_types!

    expect(::BasicObject::TypeRegistry.registry[[:instance,A]]["func"].to_s).to eq('( -> Integer)')
  end

  it 'parses type functions with functions with no arguments as argument' do
    $TYPECHECK = true
    code = <<__END
     class A
       ts '#func / Integer -> ( -> Integer) -> Integer'
       def func(i, f)
         f[]
       end
     end
__END

    eval(code)

    ::BasicObject::TypeRegistry.normalize_types!

    expect(::BasicObject::TypeRegistry.registry[[:instance,A]]["func"].to_s).to eq('(Integer,( -> Integer) -> Integer)')
  end
end
