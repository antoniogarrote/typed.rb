require_relative '../spec_helper'

describe TypedRb::Language do
  let(:language) { described_class.new }
  let(:file) { File.join(File.dirname(__FILE__), 'examples', example) }

  context 'with valid source code' do

    let(:example) { 'counter.rb' }

    it 'should be possible to type check the code' do
      language.check_file(file)
      expect_binding(language, Counter, '@counter', Integer)
    end
  end

  context 'with valid source code including conditionals' do
    let(:example) { 'if.rb' }

    it 'should be possible to type check the code' do
      language.check_file(file)
      expect_binding(language, TestIf, '@state', String)
    end
  end

  context 'with valid source code generic arrays' do
    let(:example) { 'animals.rb' }

    it 'should be possible to type check errors about array invariance' do
      expect {
        language.check_file(file)
      }.to raise_error(TypedRb::TypeCheckError,
                       'Array[Class[Animal1]] expected, Array[Class[Cat1]] found')
    end
  end
end
