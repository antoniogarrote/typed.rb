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

  context 'with monoid error example 1, inconsistent type annotation' do
    let(:example) { 'monoid/monoid_error1.rb' }

    it 'should be possible to type check the example correctly' do
      expect {
        silence_stream(STDOUT) do
          language.check_file(file, true)
        end
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context 'with monoid error example 2, inconsistent type annotation' do
    let(:example) { 'monoid/monoid_error2.rb' }

    it 'should be possible to type check the example correctly' do
      expect {
        silence_stream(STDOUT) do
          language.check_file(file, true)
        end
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context 'with monoid error example 3, inconsistent type annotation' do
    let(:example) { 'monoid/monoid_error3.rb' }

    it 'should be possible to type check the example correctly' do
      expect {
        silence_stream(STDOUT) do
          language.check_file(file, true)
        end
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context 'with monoid error example 4, inconsistent type annotation' do
    let(:example) { 'monoid/monoid_error4.rb' }

    it 'should be possible to type check the example correctly' do
      expect {
        silence_stream(STDOUT) do
          language.check_file(file, true)
        end
      }.to raise_error(TypedRb::Types::Polymorphism::UnificationError)
    end
  end

  context 'with monoid2 example, type checks correctly' do
    let(:example) { 'monoid2.rb' }

    it 'should be possible to type check the example correctly' do
      expect {
        silence_stream(STDOUT) do
          language.check_file(file, true)
        end
      }.to_not raise_error
    end
  end

  context 'with monoid2 error example 1, inconsistent type' do
    let(:example) { 'monoid2/monoid2_error1.rb' }

    it 'should be possible to type check the example correctly' do
      expect {
        silence_stream(STDOUT) do
          language.check_file(file, true)
        end
      }.to raise_error(TypedRb::Types::UncomparableTypes)
    end
  end

  context 'with equality example, type checks correctly' do
    let(:example) { 'equality.rb' }

    it 'should be possible to type check the example correctly' do
      expect {
        silence_stream(STDOUT) do
          language.check_file(file, true)
        end
      }.to_not raise_error
    end
  end

  context 'with enum example, type checks correctly' do
    let(:example) { 'enum.rb' }

    it 'should be possible to type check the example correctly' do
      expect {
        expr = File.new(file, 'r').read
        result = language.check(expr)
        expect(result.to_s).to eq('Array[Integer]')
      }.to_not raise_error
    end
  end

  context 'with enum example error1, type checks correctly' do
    let(:example) { 'enum/enum_error1.rb' }

    it 'should be possible to type check the example correctly' do
      expect {
        expr = File.new(file, 'r').read
        language.check(expr)
      }.to raise_error(TypedRb::Types::Polymorphism::UnificationError)
    end
  end

end
