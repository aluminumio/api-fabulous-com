# frozen_string_literal: true

require_relative "lib/fabulous/version"

Gem::Specification.new do |spec|
  spec.name = "fabulous"
  spec.version = Fabulous::VERSION
  spec.authors = ["Jonathan Siegel"]
  spec.email = ["<248302+usiegj00@users.noreply.github.com>"]

  spec.summary       = "Ruby client for the Fabulous.com API"
  spec.description   = "A comprehensive Ruby gem for interacting with the Fabulous.com " \
                       "domain management API with CLI support"
  spec.homepage      = "https://github.com/aluminumio/api-fabulous-com"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["{bin,lib}/**/*", "LICENSE.txt", "README.md"]
  spec.bindir = "bin"
  spec.executables = ["fabulous"]
  spec.require_paths = ["lib"]

  spec.add_dependency "dotenv", "~> 2.8"
  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "nokogiri", "~> 1.15"
  spec.add_dependency "pastel", "~> 0.8"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "tty-spinner", "~> 0.9"
  spec.add_dependency "tty-table", "~> 0.12"

  spec.add_development_dependency "pry", "~> 0.14"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "rubocop-rspec", "~> 2.20"
  spec.add_development_dependency "vcr", "~> 6.2"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "yard", "~> 0.9"
end
