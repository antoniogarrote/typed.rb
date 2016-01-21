require File.expand_path("../lib/typed/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = 'typed.rb'
  s.version     = TypedRb::VERSION
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.summary     = 'Gradual type checker for Ruby'
  s.authors     = ['Antonio Garrote']
  s.email       = 'antoniogarrote@gmail.com'
  s.homepage    = 'https://github.com/antoniogarrote/typed.rb'
  s.executables << 'typed.rb'
  s.files       = Dir['Rakefile', '{bin,lib,spec}/**/*', 'README*', 'LICENSE*']
  s.license     = 'MIT'

  s.add_dependency('parser', '~> 2.2')
  s.add_dependency('log4r', '~> 1.1')
  s.add_dependency('colorize', '~> 0.7')
end
