require_relative '../../spec_helper'

describe TypedRb::Model::TmSend do
  let(:language) { TypedRb::Language.new }

  context 'with a generic type' do
    it 'creates the correct materialised type' do
      code = <<__CODE
        ts 'type Pod1[X<Numeric]'
        class Pod1

          ts '#initialize / [X] -> unit'
          def initialize(x)
             @value = x
          end
          ts '#get / -> [X]'
          def get
            @value
          end

          ts '#put / [X] -> unit'
          def put(x)
            @value = x
          end

        end

        Pod1.(Integer)
__CODE

      result = language.check(code)
      expect(result.type_vars[0].bound.ruby_type).to eq(Integer)
    end

    it 'captures type errors in the materialization' do

      code = <<__CODE
        ts 'type Pod2[X<Numeric]'
        class Pod2

          ts '#initialize / -> unit'
          def initialize
             @value = base
          end

          ts '#base / -> Float'
          def base
            1.0
          end

          ts '#get / -> [X]'
          def get
            @value
          end

          ts '#put / [X] -> unit'
          def put(x)
            @value = x
          end

        end
__CODE

      expect {
        language.check("#{code}; Pod2.(Integer)")
      }.to raise_error(TypedRb::TypeCheckError)

      result = language.check("#{code}; Pod2.(Float)")
      expect(result.type_vars[0].bound.ruby_type).to eq(Float)
    end

    it 'returns the right type information for materialised methods' do

      code = <<__CODE
        ts 'type Pod3[X<Numeric]'
        class Pod3

          ts '#initialize / [X] -> unit'
          def initialize(x)
             @value = x
          end

          ts '#get / -> [X]'
          def get
            @value
          end

          ts '#put / [X] -> unit'
          def put(x)
            @value = x
          end
        end
__CODE

      expect {
        language.check("#{code}; p = Pod3.(Integer).new(0.0); p.put(2.0)")
      }.to raise_error(TypedRb::TypeCheckError)

      result = language.check("#{code}; p = Pod3.(Integer).new(0); p.put(2); p.get")
      expect(result.ruby_type).to eq(Integer)
    end
  end
end
