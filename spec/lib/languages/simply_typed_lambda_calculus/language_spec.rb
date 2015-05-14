# -*- coding: utf-8 -*-
describe TypedRb::Languages::SimplyTypedLambdaCalculus::Language do

  let(:lang) { described_class.new }
  let(:check) { ->(code) {
      parsed = lang.parse(code)
      puts parsed
      lang.check_type(parsed) }
  }

  context '#check_type' do

    context 'Integers' do
      it 'type checks a \'Int\' value' do
        type_checked = check['0']
        expect(type_checked).to be_compatible(TypedRb::Languages::SimplyTypedLambdaCalculus::Types::TyInteger)
      end
    end

    context 'Booleans' do
      it 'type checks a \'true\' value' do
        type_checked = check['true']
        expect(type_checked).to be_compatible(TypedRb::Languages::SimplyTypedLambdaCalculus::Types::TyBoolean)
      end

      it 'type checks a \'false\' value' do
        type_checked = check['false']
        expect(type_checked).to be_compatible(TypedRb::Languages::SimplyTypedLambdaCalculus::Types::TyBoolean)
      end
    end

    context 'Conditionals' do
      it 'type checks a boolean expression returning an integer' do
        type_checked = check[%q(
            if true
              0
            else
              1
            end
                             )]
        expect(type_checked).to be_compatible(TypedRb::Languages::SimplyTypedLambdaCalculus::Types::TyInteger)
      end

      it 'type checks a boolean expression returning a boolean' do
        type_checked = check[%q(
            if true
              true
            else
              false
            end
                             )]
        expect(type_checked).to be_compatible(TypedRb::Languages::SimplyTypedLambdaCalculus::Types::TyBoolean)
      end

      it 'throws an exception if the condition of the conditional is not boolean' do
        expect {
          type_checked = check[%q(
            if 0
              true
            else
              false
            end
                               )]
        }.to raise_error(TypedRb::Languages::SimplyTypedLambdaCalculus::Model::TypeError)
      end

      it 'throws an exception if both branches of the conditional do not have the same type' do
        expect {
          type_checked = check[%q(
            if true
              1
            else
              false
            end
                               )]
        }.to raise_error(TypedRb::Languages::SimplyTypedLambdaCalculus::Model::TypeError)
      end
    end


    context 'Abstractions' do
      it 'checks the type of a lambda function' do
        type_checked = check[%q(
            typesig Bool => Int
            ->(x) { 3 }
                             )]
        expect(type_checked).to be_compatible(TypedRb::Languages::SimplyTypedLambdaCalculus::Types::TyFunction.new(
                                                                                                                   TypedRb::Languages::SimplyTypedLambdaCalculus::Types::TyBoolean,                                                                                                                                       TypedRb::Languages::SimplyTypedLambdaCalculus::Types::TyInteger,                                                                                                                                       ))
      end

      it 'supports optional return types' do
        type_checked = check[%q(
            typesig Bool
            ->(x) { 3 }
                             )]
        expect(type_checked).to be_compatible(TypedRb::Languages::SimplyTypedLambdaCalculus::Types::TyFunction.new(
                                                                                                                   TypedRb::Languages::SimplyTypedLambdaCalculus::Types::TyBoolean,                                                                                                                                       TypedRb::Languages::SimplyTypedLambdaCalculus::Types::TyInteger,                                                                                                                                       ))
      end

      it 'checks the type of a lambda function using the context' do
        type_checked = check[%q(
            typesig Bool => Bool
            ->(x) { x }
                             )]
        expect(type_checked).to be_compatible(TypedRb::Languages::SimplyTypedLambdaCalculus::Types::TyFunction.new(
                                                                                                                   TypedRb::Languages::SimplyTypedLambdaCalculus::Types::TyBoolean,                                                                                                                                       TypedRb::Languages::SimplyTypedLambdaCalculus::Types::TyBoolean,                                                                                                                                       ))
      end

      it 'checks the type of a complex abstraction' do
        type_checked = check[%q(
              typesig Bool
              ->(x) {

                 typesig Int
                 ->(y) {

                    typesig Int
                    ->(z) { (x z) }
                 }
              }
                             )]

        puts "PARSED"
        puts type_checked
      end

      it 'detects errors in the typing' do
        expect {
        type_checked = check[%q(
            typesig Bool => Int
            ->(x) { true }
                             )]
        }.to raise_error(TypedRb::Languages::SimplyTypedLambdaCalculus::Model::TypeError)

      end
    end

    context 'Application' do

    end
  end
end