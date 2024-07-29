# frozen_string_literal: true

$LOAD_PATH.push(File.expand_path("../lib", __FILE__))

require "erb_lint/version"

Gem::Specification.new do |s|
  s.name = "erb_lint"
  s.version = ERBLint::VERSION
  s.authors = ["Justin Chan", "Shopify Developers"]
  s.email = ["ruby@shopify.com"]
  s.summary = "ERB lint tool"
  s.description = "ERB Linter tool."
  s.homepage = "https://github.com/Shopify/erb-lint"
  s.license = "MIT"

  s.files = Dir["lib/**/*.rb", "exe/*"]
  s.bindir = "exe"
  s.executables = s.files.grep(%r{^exe/}) { |f| File.basename(f) }

  s.required_ruby_version = ">= 2.7.0"

  s.metadata = {
    "allowed_push_host" => "https://rubygems.org",
  }

  s.add_dependency("activesupport")
  s.add_dependency("better_html", ">= 2.0.1")
  s.add_dependency("parser", ">= 2.7.1.4")
  s.add_dependency("rainbow")
  s.add_dependency("rubocop", "~> 1.0")
  s.add_dependency("smart_properties")

  s.add_development_dependency("rspec")
  s.add_development_dependency("rubocop")
  s.add_development_dependency("rubocop-shopify")
end
