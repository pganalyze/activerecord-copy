# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pg_data_encoder/version'

Gem::Specification.new do |gem|
  gem.name          = "pg_data_encoder"
  gem.version       = PgDataEncoder::VERSION
  gem.authors       = ["Pete Brumm"]
  gem.email         = ["pete@petebrumm.com"]
  gem.description   = %q{Creates a binary data file that can be imported into postgres's copy from command}
  gem.summary       = %q{for faster input of data into postgres you can use this to generate the binary import and run COPY FROM}
  gem.homepage      = "https://github.com/pbrumm/pg_data_encoder"
 
  gem.license       = 'MIT'
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_development_dependency("rspec", ">= 2.12.0")
  gem.add_development_dependency("rspec-core", ">= 2.12.0")
end
