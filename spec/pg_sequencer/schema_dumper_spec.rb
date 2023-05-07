# frozen_string_literal: true

require 'spec_helper'
require 'support/active_record_mocks'

describe PgSequencer::SchemaDumper do
  let(:stream) { MockStream.new }
  let(:connection) { MockConnection.new(sequences) }
  let(:sequences) do
    %w[user_seq item_seq].map do |name|
      PgSequencer::SequenceDefinition.new(name, options)
    end
  end

  context 'with all options' do
    let(:options) do
      {
        increment: 1,
        min: 1,
        max: 2_000_000,
        start: 1,
        cache: 5,
        cycle: true,
        owned_by: 'table_name.column_name',
      }
    end

    it 'outputs all sequences correctly' do
      expected_output = <<-SCHEMA.strip_heredoc
                        # Fake Schema Header
                          create_sequence "item_seq", increment: 1, min: 1, max: 2000000, start: 1, cache: 5, cycle: true, owned_by: "table_name.column_name"
                          create_sequence "user_seq", increment: 1, min: 1, max: 2000000, start: 1, cache: 5, cycle: true, owned_by: "table_name.column_name"

                        # (No Tables)
                        # Fake Schema Trailer
      SCHEMA

      MockSchemaDumper.dump(connection, stream)
      expect(expected_output.strip).to eq(stream.to_s)
    end
  end

  context 'when min specified as false' do
    let(:options) do
      {
        increment: 1,
        min: false,
        max: 2_000_000,
        start: 1,
        cache: 5,
        cycle: true,
        owned_by: 'table_name.column_name',
      }
    end

    it 'outputs false for schema output' do
      expected_output = <<-SCHEMA.strip_heredoc
                        # Fake Schema Header
                          create_sequence "item_seq", increment: 1, min: false, max: 2000000, start: 1, cache: 5, cycle: true, owned_by: "table_name.column_name"
                          create_sequence "user_seq", increment: 1, min: false, max: 2000000, start: 1, cache: 5, cycle: true, owned_by: "table_name.column_name"

                        # (No Tables)
                        # Fake Schema Trailer
      SCHEMA

      MockSchemaDumper.dump(connection, stream)
      expect(expected_output.strip).to eq(stream.to_s)
    end
  end
end
