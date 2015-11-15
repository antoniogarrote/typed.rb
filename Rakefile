require 'rspec/core/rake_task'
require 'open3'

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
  cmd = "./bin/typed.rb #{Kernel.computed_dependencies.join(' ')}"
  Open3.popen3(cmd) do |stdin, stdout, stderr, waith|
    { :out => stdout, :err => stderr }.each do |key, stream|
      Thread.new do
        until (raw_line = stream.gets).nil? do
          puts raw_line
        end
      end
    end
    waith.join
  end
end
