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
    value_instance_var = parsed.local_typing_context.type_variables_register[[:instance_variable, Pod, :@value]]
    expect(value_instance_var).to_not be_nil
    expect(value_instance_var.variable.index('Pod:@value')).to_not be_nil
    value_instance_var_constraints = parsed.local_typing_context.constraints[value_instance_var.variable]
    expect(value_instance_var_constraints.size).to eq(2)
    expect(parsed.local_typing_context.constraints['Pod:X']).to eq([[:lt, Numeric]])
  end
end
