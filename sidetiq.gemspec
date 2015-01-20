# -*- encoding: utf-8 -*-
lib = File.expand_path(File.join('..', 'lib'), __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sidetiq/version'

Gem::Specification.new do |gem|
  gem.name          = "sidetiq"
  gem.version       = Sidetiq::VERSION::STRING
  gem.authors       = ["Tobias Svensson"]
  gem.email         = ["tob@tobiassvensson.co.uk"]
  gem.description   = "Recurring jobs for Sidekiq"
  gem.summary       = gem.description
  gem.homepage      = "http://github.com/tobiassvn/sidetiq"
  gem.license       = "3-clause BSD"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.extensions    = []

  gem.add_dependency 'sidekiq',   '>= 3.0.0'
  gem.add_dependency 'celluloid', '>= 0.14.1'
  gem.add_dependency 'ice_cube',  '0.12.1'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'sinatra'
  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'rack-test'
  gem.add_development_dependency 'minitest', '~> 5.0.7'

  if RUBY_PLATFORM != "java"
    gem.add_development_dependency 'coveralls'
  end
end
