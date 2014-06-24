# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudconfig/version'

Gem::Specification.new do |spec|
  spec.name          = "cloudconfig"
  spec.version       = Cloudconfig::VERSION
  spec.authors       = ["Katrin Nilsson", "Carl Loa Odin", "Olle Lundberg"]
  spec.email         = ["katrin.nilsson@klarna.com", "carl.loa.odin@klarna.com", "olle.lundberg@klarna.com"]
  spec.description   = %q{Cloudconfig is an application that manages configurations for resources in Cloudstack.}
  spec.summary       = %q{Resource configuration manager for Cloudstack.}
  spec.homepage      = ""
  spec.license       = "Apache License, Version 2.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.3.2"

  spec.add_runtime_dependency "thor", "~> 0.19.1"
  spec.add_runtime_dependency "user_config", "~> 0.0.4"
  spec.add_runtime_dependency "cloudstack_ruby_client", "~> 1.0.1"
end
