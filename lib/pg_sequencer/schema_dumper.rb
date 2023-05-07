# frozen_string_literal: true

module PgSequencer
  # This module enhances ActiveRecord::SchemaDumper
  # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/schema_dumper.rb
  module SchemaDumper
    def tables(stream)
      sequences(stream)
      super(stream)
    end

  protected

    OPTIONS = %i[increment min max start cache cycle owned_by].freeze

    def parts(name, options)
      ["create_sequence #{name.inspect}"] +
        OPTIONS.map { |m| "#{m}: #{options[m].inspect}" }
    end

    def unmanaged_sequences
      @connection.sequences
                 .reject { |sequence| sequence.options[:owner_is_primary_key] }
    end

    def sequence_statements
      r = unmanaged_sequences.map { |sequence| "  #{parts(sequence.name, sequence.options).join(', ')}" }
      r.sort!
    end

    def sequences(stream)
      stream.puts sequence_statements.join("\n")
      stream.puts
    end
  end
end
