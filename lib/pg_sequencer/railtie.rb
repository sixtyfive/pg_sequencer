# frozen_string_literal: true

require 'rails/railtie'

module PgSequencer
  # Really ties the room together
  class Railtie < Rails::Railtie
    initializer 'pg_sequencer.load_adapter' do
      ActiveSupport.on_load :active_record do
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.include(PgSequencer::ConnectionAdapters::PostgresqlAdapter)
        ActiveRecord::SchemaDumper.prepend(PgSequencer::SchemaDumper)
        ActiveRecord::Migration::CommandRecorder.include(PgSequencer::RollbackSupport)
      end
    end
  end
end
