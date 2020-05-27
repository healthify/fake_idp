# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fake_idp/version'

Gem::Specification.new do |spec|
  spec.name          = "fake_idp"
  spec.version       = FakeIdp::VERSION
  spec.authors       = [
    "Shelby Switzer",
    "Tyler Willingham",
    "Robyn-Dale Samuda",
    "Chet Bortz",
  ]
  spec.email         = ["engineering@healthify.us"]

  spec.summary       = 'Fake IDP to test SAML authentication'
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", ">= 1.10.5"
  spec.add_dependency "builder", ">= 3.2.2"
  spec.add_dependency "activesupport", "~> 5.2.4.3"
  spec.add_dependency "xmlenc", ">= 0.7.1"

  spec.add_development_dependency "bundler", "~> 2"
  spec.add_development_dependency "ruby-saml", "~> 1.11.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "dotenv", "~> 1.0"
  spec.add_development_dependency "pry", "~> 0.12.2"

  spec.add_runtime_dependency "sinatra", "~> 2.0.0"
  spec.add_runtime_dependency "ruby-saml-idp"
end
