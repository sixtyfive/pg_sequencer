module PgSequencer
  class Railtie < Rails::Railtie
    initializer "pg_sequencer.load_adapter" do
      ActiveSupport.on_load :active_record do
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.include(PgSequencer::ConnectionAdapters::PostgreSQLAdapter)
        ActiveRecord::SchemaDumper.prepend(PgSequencer::SchemaDumper)
      end
    end
  end
end
