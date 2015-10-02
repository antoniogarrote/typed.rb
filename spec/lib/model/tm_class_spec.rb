require_relative '../../spec_helper'

describe TypedRb::Model::TmClass do
  let(:language) { TypedRb::Language.new }

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

    parsed = language.check(code)

    expect(parsed).to be_instance_of(TypedRb::Types::TyGenericSingletonObject)
    value_instance_var = parsed.local_typing_context.type_variables_register[[:instance_variable, Pod, :@value]]
    expect(value_instance_var).to_not be_nil
    expect(value_instance_var.variable.index('Pod:@value')).to_not be_nil
    value_instance_var_constraints = parsed.local_typing_context.constraints[value_instance_var.variable]
    expect(value_instance_var_constraints.size).to eq(2)
  end

  it 'handles nested classes' do
    code = <<__CODE
       module TCNS
         class TC
           ts '#test / -> Integer'
           def test; 1; end
         end
       end

       TCNS::TC.new.test
__CODE

    result = language.check(code)
    expect(result.ruby_type).to eq(Integer)
  end

  it 'handles nested classes in return arguments' do
    code = <<__CODE
       module TCNS
         class TC2; end
         class TC3
           ts '#test / -> Class'
           def test; TC2; end
         end
       end

       TCNS::TC3.new.test
__CODE

    result = language.check(code)
    expect(result.ruby_type).to eq(Class)
  end
end
