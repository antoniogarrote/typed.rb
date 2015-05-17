# -*- coding: utf-8 -*-
describe TypedRb::Languages::TypedLambdaCalculus::Language do

  let(:lang) { described_class.new }
  let(:check) { ->(code) {
    parsed = lang.parse(code)
    #puts "-----------------"
    #puts parsed
    lang.check_type(parsed) }
  }

  context '#check_type' do

    context 'Integers' do
      it 'type checks a \'Int\' value' do
        type_checked = check['0']
        expect(type_checked).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyInteger)
      end
    end

    context 'Booleans' do
      it 'type checks a \'true\' value' do
        type_checked = check['true']
        expect(type_checked).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyBoolean)
      end

      it 'type checks a \'false\' value' do
        type_checked = check['false']
        expect(type_checked).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyBoolean)
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
        expect(type_checked).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyInteger)
      end

      it 'type checks a boolean expression returning a boolean' do
        type_checked = check[%q(
            if true
              true
            else
              false
            end
                             )]
        expect(type_checked).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyBoolean)
      end

      it 'throws an exception if the condition of the conditional is not boolean' do
        expect {
          check[%q(
            if 0
              true
            else
              false
            end
                               )]
        }.to raise_error(TypedRb::Languages::TypedLambdaCalculus::Model::TypeError)
      end

      it 'throws an exception if both branches of the conditional do not have the same type' do
        expect {
          check[%q(
            if true
              1
            else
              false
            end
                               )]
        }.to raise_error(TypedRb::Languages::TypedLambdaCalculus::Model::TypeError)
      end
    end


    context 'Abstractions' do
      it 'checks the type of a lambda function' do
        type_checked = check[%q(
            typesig 'Bool => Int'
            ->(x) { 3 }
                             )]
        expect(type_checked).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyFunction.new(
                                                  TypedRb::Languages::TypedLambdaCalculus::Types::TyBoolean,
                                                  TypedRb::Languages::TypedLambdaCalculus::Types::TyInteger))
      end

      it 'supports optional return types' do
        type_checked = check[%q(
            typesig 'Bool => Int'
            ->(x) { 3 }
                             )]
        expect(type_checked).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyFunction.new(
                                                  TypedRb::Languages::TypedLambdaCalculus::Types::TyBoolean,
                                                  TypedRb::Languages::TypedLambdaCalculus::Types::TyInteger))
      end

      it 'checks the type of a lambda function using the context' do
        type_checked = check[%q(
            typesig 'Bool => Bool'
            ->(x) { x }
                             )]
        expect(type_checked).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyFunction.new(
                                                  TypedRb::Languages::TypedLambdaCalculus::Types::TyBoolean,
                                                  TypedRb::Languages::TypedLambdaCalculus::Types::TyBoolean,))
      end


      it 'detects errors in the typing' do
        expect {
          check[%q(
            typesig 'Bool => Int'
            ->(x) { true }
                             )]
        }.to raise_error(TypedRb::Languages::TypedLambdaCalculus::Model::TypeError)

      end

      it 'checks the type of a complex abstraction' do
        type_checked = check[%q(
              typesig 'Bool => Int => (Bool => Int) => Int'
              ->(x) {

                 typesig 'Int => (Bool => Int) => Int'
                 ->(y) {

                    typesig '(Bool => Int) => Int'
                    ->(z) { z[x] }
                 }
              }
                             )]

        expect(type_checked).to be_compatible(
                                    TypedRb::Languages::TypedLambdaCalculus::Types::TyFunction.new(
                                        TypedRb::Languages::TypedLambdaCalculus::Types::TyBoolean,
                                        TypedRb::Languages::TypedLambdaCalculus::Types::TyFunction.new(
                                            TypedRb::Languages::TypedLambdaCalculus::Types::TyInteger,
                                            TypedRb::Languages::TypedLambdaCalculus::Types::TyFunction.new(
                                                TypedRb::Languages::TypedLambdaCalculus::Types::TyFunction.new(
                                                    TypedRb::Languages::TypedLambdaCalculus::Types::TyBoolean,
                                                    TypedRb::Languages::TypedLambdaCalculus::Types::TyInteger),
                                                TypedRb::Languages::TypedLambdaCalculus::Types::TyInteger)))
                                )

      end

      it 'checks errors in complex abstraction' do
        expect {
          check[%q(
              typesig 'Bool => Int => (Bool => Int) => Int'
              ->(x) {

                 typesig 'Int => (Bool => Int) => Int'
                 ->(y) {

                    typesig '(Bool => Int) => Bool'
                    ->(z) { z[x] }
                 }
              }
                             )]
        }.to raise_error(TypedRb::Languages::TypedLambdaCalculus::Model::TypeError)

        expect {
          check[%q(
              typesig 'Bool => Int => (Bool => Int) => Int'
              ->(x) {

                 typesig 'Int => (Bool => Int) => Int'
                 ->(y) {

                    typesig '(Bool => Int) => Int'
                    ->(z) { z[y] }
                 }
              }
                             )]
        }.to raise_error(TypedRb::Languages::TypedLambdaCalculus::Model::TypeError)
      end
    end

    context 'Application' do

      it 'checks function application' do
        type_checked = check[%q(
              typesig 'Bool => Int'
              ->(x) { 0 }[true]
         )]

        expect(type_checked).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyInteger)
      end

      it 'checks errors in function application' do
        expect {
          check[%q(
              typesig 'Bool => Int'
              ->(x) { 0 }[3434]
         )]

        }.to raise_error(TypedRb::Languages::TypedLambdaCalculus::Model::TypeError)
      end
    end
  end
end
