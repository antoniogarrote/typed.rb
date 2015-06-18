require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  RSpec::Core::RakeTask.new(:arithmetic_expressions) do |t|
    t.pattern = 'spec/lib/languages/arithmetic_expressions/**/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:untyped_lambda_calculus) do |t|
    t.pattern = 'spec/lib/languages/untyped_lambda_calculus/**/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:simply_typed_lambda_calculus) do |t|
    t.pattern = 'spec/lib/languages/simply_typed_lambda_calculus//**/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:typed_lambda_calculus) do |t|
    t.pattern = 'spec/lib/languages/typed_lambda_calculus/**/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:poly_featherweight_ruby) do |t|
    t.pattern = 'spec/lib/languages/poly_featherweight_ruby/**/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:featherweight_ruby) do |t|
    t.pattern = 'spec/lib/languages/featherweight_ruby/**/*_spec.rb'
  end
end
