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

  before do
    MockSchemaDumper.dump(connection, stream)
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

    let(:expected_output) do
      <<~SCHEMA
        # Fake Schema Header
        # (No Tables)
          create_sequence "item_seq", increment: 1, min: 1, max: 2000000, start: 1, cache: 5, cycle: true, owned_by: "table_name.column_name"
          create_sequence "user_seq", increment: 1, min: 1, max: 2000000, start: 1, cache: 5, cycle: true, owned_by: "table_name.column_name"

        # Fake Schema Trailer
      SCHEMA
    end

    it 'outputs all sequences correctly' do
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

    let(:expected_output) do
      <<~SCHEMA
        # Fake Schema Header
        # (No Tables)
          create_sequence "item_seq", increment: 1, min: false, max: 2000000, start: 1, cache: 5, cycle: true, owned_by: "table_name.column_name"
          create_sequence "user_seq", increment: 1, min: false, max: 2000000, start: 1, cache: 5, cycle: true, owned_by: "table_name.column_name"

        # Fake Schema Trailer
      SCHEMA
    end

    it 'outputs false for schema output' do
      expect(expected_output.strip).to eq(stream.to_s)
    end
  end
end
