lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "pg_sequencer/version"

Gem::Specification.new do |spec|
  spec.name           = "pg_sequencer"
  spec.version        = PgSequencer::VERSION
  spec.authors        = ["Tony Collen", "Aaron Ackerman", "Ben Linton", "J. R. Schmid"]
  spec.email          = ["tonyc@code42.com"]
  spec.homepage       = "https://github.com/code42/pg_sequencer/"
  spec.license        = "MIT"
  spec.summary        = "Manage postgres sequences in rails migrations"
  spec.description    = "Sequences need some love. pg_sequencer teaches Rails what sequences are, and will dump them to schema.rb, and also lets you create/drop sequences in migrations."

  spec.files          = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(\test|spec|features)/}) }
  spec.bindir         = "bin"
  spec.executables    = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths  = ["lib"]

  spec.required_ruby_version = ">= 2.7.8"

  spec.add_runtime_dependency "activesupport", ">= 6.1.0"
  spec.add_runtime_dependency "activerecord", ">= 6.1.0"

  spec.add_development_dependency "pg", ">= 1.5.3"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
