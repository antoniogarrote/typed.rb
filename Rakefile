require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

namespace :spec do
  RSpec::Core::RakeTask.new(:poly_featherweight_ruby) do |t|
    t.rspec_opts = 'spec/lib/languages/poly_featherweight_ruby'
  end
end
