# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'pg_sequencer/version'

Gem::Specification.new do |spec|
  spec.name           = 'pg_sequencer'
  spec.version        = PgSequencer::VERSION
  spec.authors        = ['Barry Allard']
  spec.email          = ['barry.allard@gmail.com']
  spec.homepage       = 'https://github.com/steakknife/pg_sequencer'
  spec.license        = 'MIT'
  spec.summary        = 'Manage postgres sequences in rails migrations'
  spec.description    = 'Sequences need some love. pg_sequencer teaches Rails what sequences are, and will dump them to schema.rb, and also lets you create/drop sequences in migrations.'

  spec.files          = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(\test|spec|features)/}) }
  spec.bindir         = 'bin'
  spec.executables    = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths  = ['lib']

  spec.required_ruby_version = '>= 3.0.0'

  spec.add_dependency 'activerecord', '>= 3.0.0'
  spec.add_dependency 'activesupport', '>= 3.0.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'pg'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-faker'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rails'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'rubocop-thread_safety'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
