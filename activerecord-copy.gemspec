# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'activerecord-copy/version'

Gem::Specification.new do |gem|
  gem.name          = 'activerecord-copy'
  gem.version       = ActiveRecordCopy::VERSION
  gem.authors       = ['Lukas Fittl']
  gem.email         = ['lukas@fittl.com']
  gem.description   = 'Supports binary COPY into PostgreSQL with activerecord'
  gem.summary       = 'Convenient methods to load data quickly into Postgres'
  gem.homepage      = 'https://github.com/lfittl/activerecord-copy'

  gem.license       = 'MIT'
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency('activerecord', '>= 3.1')

  gem.add_development_dependency('rspec', '>= 2.12.0')
  gem.add_development_dependency('rspec-core', '>= 2.12.0')
  gem.add_development_dependency('rgeo', '>= 2.4.0')
end
