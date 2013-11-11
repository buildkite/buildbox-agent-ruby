# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'buildbox/version'

Gem::Specification.new do |spec|
  spec.name          = "buildbox"
  spec.version       = Buildbox::VERSION
  spec.authors       = ["Keith Pitt"]
  spec.email         = ["me@keithpitt.com"]
  spec.description   = %q{Ruby agent for buildbox}
  spec.summary       = %q{Ruby agent for buildbox}
  spec.homepage      = "https://github.com/buildboxhq/agent"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'faraday',            '~> 0.8'
  spec.add_dependency 'faraday_middleware', '~> 0.9'
  spec.add_dependency 'hashie',             '~> 2.0'
  spec.add_dependency 'multi_json',         '~> 1.7'
  spec.add_dependency 'celluloid',          '~> 0.14'
  spec.add_dependency 'childprocess',       '~> 0.3'
  spec.add_dependency 'mime-types',         '~> 2.0'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'webmock'
end
