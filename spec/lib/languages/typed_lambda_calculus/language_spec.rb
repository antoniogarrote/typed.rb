# -*- coding: utf-8 -*-
require_relative './spec_helper'

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
            typesig 'Bool -> Int'
            ->(x) { 3 }
                             )]
        expect(type_checked).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyFunction.new(
                                                  TypedRb::Languages::TypedLambdaCalculus::Types::TyBoolean,
                                                  TypedRb::Languages::TypedLambdaCalculus::Types::TyInteger))
      end

      it 'supports optional return types' do
        type_checked = check[%q(
            typesig 'Bool -> Int'
            ->(x) { 3 }
                             )]
        expect(type_checked).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyFunction.new(
                                                  TypedRb::Languages::TypedLambdaCalculus::Types::TyBoolean,
                                                  TypedRb::Languages::TypedLambdaCalculus::Types::TyInteger))
      end

      it 'checks the type of a lambda function using the context' do
        type_checked = check[%q(
            typesig 'Bool -> Bool'
            ->(x) { x }
                             )]
        expect(type_checked).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyFunction.new(
                                                  TypedRb::Languages::TypedLambdaCalculus::Types::TyBoolean,
                                                  TypedRb::Languages::TypedLambdaCalculus::Types::TyBoolean,))
      end


      it 'checks the type of expressions containing sequencing' do
        code = <<__END
       (
          typesig 'Int -> Int'
          ->(x) { x }
          typesig 'Bool -> Bool'
          ->(y) { y }
       )[true]
__END
        type_checked = check[code]

        expect(type_checked).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyBoolean)
      end
      it 'detects errors in the typing' do
        expect {
          check[%q(
            typesig 'Bool -> Int'
            ->(x) { true }
                             )]
        }.to raise_error(TypedRb::Languages::TypedLambdaCalculus::Model::TypeError)

      end

      it 'checks the type of a complex abstraction' do
        type_checked = check[%q(
              typesig 'Bool -> Int -> (Bool -> Int) -> Int'
              ->(x) {

                 typesig 'Int -> (Bool -> Int) -> Int'
                 ->(y) {

                    typesig '(Bool -> Int) -> Int'
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
              typesig 'Bool -> Int -> (Bool -> Int) -> Int'
              ->(x) {

                 typesig 'Int -> (Bool -> Int) -> Int'
                 ->(y) {

                    typesig '(Bool -> Int) -> Bool'
                    ->(z) { z[x] }
                 }
              }
                             )]
        }.to raise_error(TypedRb::Languages::TypedLambdaCalculus::Model::TypeError)

        expect {
          check[%q(
              typesig 'Bool -> Int -> (Bool -> Int) -> Int'
              ->(x) {

                 typesig 'Int -> (Bool -> Int) -> Int'
                 ->(y) {

                    typesig '(Bool -> Int) -> Int'
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
              typesig 'Bool -> Int'
              ->(x) { 0 }[true]
         )]

        expect(type_checked).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyInteger)
      end

      it 'checks errors in function application' do
        expect {
          check[%q(
              typesig 'Bool -> Int'
              ->(x) { 0 }[3434]
         )]

        }.to raise_error(TypedRb::Languages::TypedLambdaCalculus::Model::TypeError)
      end

      it 'checks expresions including let expressions for functions' do
        code = <<__END
        typesig 'Int -> Int'
        id_int = ->(x) { x }
        my_int = 3
        my_bool = true

        id_int[my_int]
__END
        expect(check[code]).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyInteger)
      end

      it 'checks missing vars in context' do
        expect {
          code = <<__END
        typesig 'Int -> Int'
        id_int = ->(x) { x }
        my_int = 3
        my_bool = true

        id_int[val]
__END
          check[code]
        }.to raise_error(TypedRb::Languages::TypedLambdaCalculus::Model::TypeError)
      end

      it 'checks type errors with let bindings' do
        expect {
          code = <<__END
        typesig 'Int -> Int'
        id_int = ->(x) { x }
        my_int = 3
        my_bool = true

        id_int[my_bool]
__END
          check[code]
        }.to raise_error(TypedRb::Languages::TypedLambdaCalculus::Model::TypeError)
      end

      it 'checks recursive functions' do
        code = <<__END
         typesig 'Int -> Int'
         rec = ->(x) { rec[3] }
         rec[3]
__END
        expect(check[code]).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyInteger)
      end

      it 'checks the type of an error type' do
        expect(check['raise Exception.new']).to be_instance_of(TypedRb::Languages::TypedLambdaCalculus::Types::TyError)
      end

      it 'returns the right type when mixing errors with other types in conditionals' do
        code = <<__END
          if true
             1
          else
             fail Exception, 'test'
          end
__END
        expect(check[code]).to be_instance_of(TypedRb::Languages::TypedLambdaCalculus::Types::TyInteger)
      end

      it 'returns the right type when mixing errors with function abstraction' do
        code = <<__END
          typesig 'Bool -> Int'
          ->(x) { raise(Error,'error') }
__END
        expect(check[code]).to be_compatible(TypedRb::Languages::TypedLambdaCalculus::Types::TyFunction.new(
                                                 TypedRb::Languages::TypedLambdaCalculus::Types::TyBoolean,
                                                 TypedRb::Languages::TypedLambdaCalculus::Types::TyInteger))

        expect {
          code = <<__END
          typesig 'Bool -> Int'
          ->(x) { raise(Error,'error'); false }
__END
          check[code]
        }.to raise_error(TypedRb::Languages::TypedLambdaCalculus::Model::TypeError)
      end
    end
  end
end
