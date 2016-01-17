require File.expand_path("../lib/typed/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = 'typed.rb'
  s.version     = TypedRb::VERSION
  s.date        = '2016-01-17'
  s.summary     = 'Gradual type checker for Ruby'
  s.authors     = ['Antonio Garrote']
  s.email       = 'antoniogarrote@gmail.com'
  s.homepage    = 'https://github.com/antoniogarrote/typed.rb'
  s.executables << 'typed.rb'
  s.files       = Dir['Rakefile', '{bin,lib,spec}/**/*', 'README*', 'LICENSE*']
  s.license     = 'MIT'
end