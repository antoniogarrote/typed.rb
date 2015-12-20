require_relative '../../spec_helper'

describe TypedRb::Model::TmCaseWhen do
  let(:language) { TypedRb::Language.new }

  it 'type checks a simple case/when statement' do
    code = <<__CODE
      a = 'a'
      case a
      when 'a'
        a
      when 'b'
        a
      else
        'other'
      end
__CODE

    parsed = language.check(code)
    expect(parsed.ruby_type).to eq(String)
  end

  it 'Promotes types to union type in case/when expressions' do
    code = <<__CODE
      a = 'a'
      case a
      when 'a'
        a
      when 'b'
        0
      else
        'other'
      end
__CODE

    parsed = language.check(code)
    expect(parsed.ruby_type).to eq(Object)
  end
end
