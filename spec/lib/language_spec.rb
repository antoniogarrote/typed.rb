require_relative '../spec_helper'

def silence_stream(stream)
  old_stream = stream.dup
  stream.reopen(RbConfig::CONFIG['host_os'] =~ /mswin|mingw/ ? 'NUL:' : '/dev/null')
  stream.sync = true
  yield
ensure
  stream.reopen(old_stream)
  old_stream.close
end

describe TypedRb::Language do
  let(:language) { described_class.new }
  let(:file) { File.join(File.dirname(__FILE__), 'examples', example) }

  context 'with valid source code' do

    let(:example) { 'counter.rb' }

    it 'should be possible to type check the code' do
      silence_stream(STDOUT) do
        language.check_file(file, true)
      end
      expect_binding(language, Counter, '@counter', Integer)
    end
  end

  context 'with valid source code including conditionals' do
    let(:example) { 'if.rb' }

    it 'should be possible to type check the code' do
      silence_stream(STDOUT) do
        language.check_file(file, true)
      end
      expect_binding(language, TestIf, '@state', String)
    end
  end

  context 'with valid source code generic arrays' do
    let(:example) { 'animals.rb' }

    it 'should be possible to type check errors about array invariance' do
      expect {
        silence_stream(STDOUT) do
          language.check_file(file, true)
        end
      }.to raise_error(TypedRb::TypeCheckError,
                       /Error type checking message sent 'mindless_func': Array\[Animal1\] expected, Array\[Cat1\] found/)
    end
  end

  context 'with monoid example' do
    let(:example) { 'monoid.rb' }

    it 'should be possible to type check the example correctly' do
      expect {
        silence_stream(STDOUT) do
          language.check_file(file, true)
        end
      }.not_to raise_error
    end
  end

  context 'with monoid error example, inconsistent type annotation' do
    let(:example) { 'monoid/monoid_error1.rb' }

    it 'should be possible to type check the example correctly' do
      expect {
        silence_stream(STDOUT) do
          language.check_file(file, true)
        end
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context 'with monoid error example, inconsistent type annotation' do
    let(:example) { 'monoid/monoid_error2.rb' }

    it 'should be possible to type check the example correctly' do
      expect {
        silence_stream(STDOUT) do
          language.check_file(file, true)
        end
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context 'with monoid error example, inconsistent type annotation' do
    let(:example) { 'monoid/monoid_error3.rb' }

    it 'should be possible to type check the example correctly' do
      expect {
        silence_stream(STDOUT) do
          language.check_file(file, true)
        end
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context 'with monoid error example, inconsistent type annotation' do
    let(:example) { 'monoid/monoid_error4.rb' }

    it 'should be possible to type check the example correctly' do
      expect {
        silence_stream(STDOUT) do
          language.check_file(file, true)
        end
      }.to raise_error(TypedRb::Types::Polymorphism::UnificationError)
    end
  end
end
