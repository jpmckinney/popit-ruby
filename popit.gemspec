# -*- encoding: utf-8 -*-
require File.expand_path('../lib/popit/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "popit"
  s.version     = PopIt::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["James McKinney"]
  s.homepage    = "https://github.com/jpmckinney/popit-ruby"
  s.summary     = %q{The PopIt API Ruby Gem}
  s.description = %q{A Ruby wrapper for the PopIt API}
  s.license     = 'MIT'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency('httparty', '~> 0.10.0')

  s.add_development_dependency('coveralls')
  s.add_development_dependency('rake')
  s.add_development_dependency('rspec', '~> 3.1')
end
