# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'buildbox/version'

Gem::Specification.new do |spec|
  spec.name          = "buildbox"
  spec.version       = Buildbox::VERSION
  spec.authors       = ["Keith Pitt"]
  spec.email         = ["me@keithpitt.com"]
  spec.description   = %q{Ruby client for buildbox}
  spec.summary       = %q{Ruby client for buildbox}
  spec.homepage      = ""
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
end
