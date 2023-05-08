# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'sequence options SQL' do |opts, expected|
  it opts.to_s do
    actual = dummy.sequence_options_sql(opts)
    expect(actual).to eq(expected)
  end
end

RSpec.shared_examples 'sequence more options SQL' do |more_options, expected|
  it more_options.to_s do
    actual = dummy.sequence_options_sql(options.merge(more_options))
    expect(actual).to eq(expected)
  end
end

describe PgSequencer::ConnectionAdapters::PostgresqlAdapter do
  let(:dummy) { Object.new.extend(described_class) }
  let(:options) do
    {
      increment: 1,
      min: 1,
      max: 2_000_000,
      cache: 5,
      cycle: true,
      owned_by: 'table_name.column_name',
    }
  end

  describe '#sequence_options_sql' do
    context 'with all options' do
      output = ' INCREMENT BY 1 MINVALUE 1 MAXVALUE 2000000 START WITH 1 CACHE 5 CYCLE OWNED BY table_name.column_name'
      include_examples 'sequence more options SQL', { start: 1 }, output
    end

    describe ':increment' do
      include_examples 'sequence options SQL', { increment: 1 }, ' INCREMENT BY 1'
      include_examples 'sequence options SQL', { increment: 2 }, ' INCREMENT BY 2'
      include_examples 'sequence options SQL', { increment: nil }, ''
    end

    describe ':min' do
      include_examples 'sequence options SQL', { min: 1 }, ' MINVALUE 1'
      include_examples 'sequence options SQL', { min: 2 }, ' MINVALUE 2'
      include_examples 'sequence options SQL', { min: nil }, ''
      include_examples 'sequence options SQL', { min: false }, ' NO MINVALUE'
    end

    describe ':max' do
      include_examples 'sequence options SQL', { max: 1 }, ' MAXVALUE 1'
      include_examples 'sequence options SQL', { max: 2 }, ' MAXVALUE 2'
      include_examples 'sequence options SQL', { max: nil }, ''
      include_examples 'sequence options SQL', { max: false }, ' NO MAXVALUE'
    end

    describe ':start' do
      include_examples 'sequence options SQL', { start: 1 }, ' START WITH 1'
      include_examples 'sequence options SQL', { start: 2 }, ' START WITH 2'
      include_examples 'sequence options SQL', { start: 500 }, ' START WITH 500'
      include_examples 'sequence options SQL', { start: nil }, ''
      include_examples 'sequence options SQL', { start: false }, ''
    end

    describe ':cache' do
      include_examples 'sequence options SQL', { cache: 1 }, ' CACHE 1'
      include_examples 'sequence options SQL', { cache: 2 }, ' CACHE 2'
      include_examples 'sequence options SQL', { cache: 500 }, ' CACHE 500'
      include_examples 'sequence options SQL', { cache: nil }, ''
      include_examples 'sequence options SQL', { cache: false }, ''
    end

    describe ':cycle' do
      include_examples 'sequence options SQL', { cycle: true }, ' CYCLE'
      include_examples 'sequence options SQL', { cycle: false }, ' NO CYCLE'
      include_examples 'sequence options SQL', { cycle: nil }, ''
    end

    describe ':owned_by' do
      include_examples 'sequence options SQL', { owned_by: 'user.counter' }, ' OWNED BY user.counter'
      include_examples 'sequence options SQL', { owned_by: 'orders.number' }, ' OWNED BY orders.number'
      include_examples 'sequence options SQL', { owned_by: false }, ''
      include_examples 'sequence options SQL', { owned_by: nil }, ''
    end
  end

  describe '#create_sequence_sql' do
    context 'without options, generates the proper SQL' do
      it { expect(dummy.create_sequence_sql('things')).to eq('CREATE SEQUENCE things') }
      it { expect(dummy.create_sequence_sql('blahs')).to eq('CREATE SEQUENCE blahs') }
    end

    context 'with options, includes options at the end' do
      let(:output) { 'CREATE SEQUENCE things INCREMENT BY 1 MINVALUE 1 MAXVALUE 2000000 START WITH 1 CACHE 5 CYCLE OWNED BY table_name.column_name' }

      it { expect(dummy.create_sequence_sql('things', options.merge(start: 1))).to eq(output) }
    end
  end

  describe '#change_sequence_sql' do
    context 'without options, returns a blank SQL statement' do
      it { expect(dummy.change_sequence_sql('things')).to eq('') }
      it { expect(dummy.change_sequence_sql('things', {})).to eq('') }
      it { expect(dummy.change_sequence_sql('things', nil)).to eq('') }
    end

    context 'with options, includes options at the end' do
      let(:output) { 'ALTER SEQUENCE things INCREMENT BY 1 MINVALUE 1 MAXVALUE 2000000 RESTART WITH 1 CACHE 5 CYCLE OWNED BY table_name.column_name' }

      it { expect(dummy.change_sequence_sql('things', options.merge(restart: 1))).to eq(output) }
    end
  end

  describe '#drop_sequence_sql' do
    it { expect(dummy.drop_sequence_sql('users_seq')).to eq('DROP SEQUENCE users_seq') }
    it { expect(dummy.drop_sequence_sql('items_seq')).to eq('DROP SEQUENCE items_seq') }
  end
end
