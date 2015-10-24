require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc 'type checks the library itself'
task :check_lib do
  $TYPECHECK = false
  $LOAD_TO_TYPECHECK = true
  require_relative './lib/init'
  $LOAD_TO_TYPECHECK = false
  puts ' * Dependencies'
  Kernel.computed_dependencies.each { |f| puts " - #{f}" }
  puts ' * Type Checking'
  `./bin/typed.rb #{Kernel.computed_dependencies.join(' ')}`
end
