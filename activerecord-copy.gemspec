require 'English'

lib = File.expand_path('lib', __dir__)
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
  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
  gem.required_ruby_version = '>= 2.5.0'

  gem.add_dependency('activerecord', '>= 3.1')
  gem.add_dependency('pg', '>= 1.3.0')

  gem.add_development_dependency('rspec', '>= 2.12.0')
  gem.add_development_dependency('rspec-core', '>= 2.12.0')
  gem.add_development_dependency('rspec-rails')

  gem.add_development_dependency('activerecord-postgis-adapter', '~> 7.1')
  gem.add_development_dependency('dotenv-rails', '>= 2.7.6')
  gem.add_development_dependency('rails', '>= 6.1.4.4')
  gem.add_development_dependency('rgeo', '>= 2.4.0')
  gem.add_development_dependency('rubocop', '~> 1.26')
  gem.add_development_dependency('rubocop-rspec', '~> 2.9.0')
  gem.metadata['rubygems_mfa_required'] = 'true'
end
