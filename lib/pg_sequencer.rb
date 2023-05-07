# frozen_string_literal: true

require 'active_record'
require 'active_support'

require 'pg_sequencer/version'
require 'pg_sequencer/connection_adapters/postgresql_adapter'
require 'pg_sequencer/sequence_definition'
require 'pg_sequencer/schema_dumper'

if defined?(:Rails)
  require 'pg_sequencer/rollback_support'
  require 'pg_sequencer/railtie'
end

# Sequence migration helpers for active_record
module PgSequencer
end
