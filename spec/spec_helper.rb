require 'pry'
# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# The `.rspec` file also contains a few flags that are not defaults but that
# users commonly want.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # The settings below are suggested to provide a good initial experience
  # with RSpec, but feel free to customize to your heart's content.
end

# Load all files
require_relative '../lib/init'

def tyobject(klass)
  TypedRb::Types::TyObject.new(klass)
end

def tyinteger
  TypedRb::Types::TyObject.new(Integer)
end

def tystring
  TypedRb::Types::TyObject.new(String)
end

def tyunit
  TypedRb::Types::TyUnit.new
end

def tyboolean
  TypedRb::Types::TyBoolean.new
end

def tyvariable(name)
  TypedRb::Types::Polymorphism::TypeVariable.new(name)
end

def eval_with_ts(code)
  ::BasicObject::TypeRegistry.clear
  $TYPECHECK = true
  eval(code)
  ::BasicObject::TypeRegistry.normalize_types!
end

def find_instance_variable_for(klass, variable, language)
  language.type_variables.detect{ |v| v.to_s =~ /#{klass}:#{variable}/ }
end

def expect_binding(language, klass, variable, type)
  var = find_instance_variable_for(klass, variable, language)
  expect(var.bound).to_not be_nil
  expect(var.bound.ruby_type).to be(type)
end

def top_level_typing_context
  TypedRb::Types::TypingContext.top_level
end

def parse(expr)
  TypedRb::Model::GenSym.reset
  TypedRb::AstParser.new.parse(expr)
end

class TypedRb::Types::TypingContext
  class << self
    def type_variables_register=(other)
      @type_variables_register = other
    end
  end
end
