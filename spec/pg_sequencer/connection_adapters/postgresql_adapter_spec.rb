# frozen_string_literal: true

require 'spec_helper'

describe PgSequencer::ConnectionAdapters::PostgreSQLAdapter do # rubocop:disable Metrics/BlockLength
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

  context 'generating sequence option SQL' do # rubocop:disable Metrics/BlockLength
    it 'includes all options' do
      output = ' INCREMENT BY 1 MINVALUE 1 MAXVALUE 2000000 START WITH 1 CACHE 5 CYCLE OWNED BY table_name.column_name'
      expect(dummy.sequence_options_sql(options.merge(start: 1))).to eq(output)
    end

    context 'for :increment' do
      it "includes 'INCREMENT BY' in the SQL" do
        expect(dummy.sequence_options_sql(increment: 1)).to eq(' INCREMENT BY 1')
        expect(dummy.sequence_options_sql(increment: 2)).to eq(' INCREMENT BY 2')
      end

      it 'does not include the option if nil value specified' do
        expect(dummy.sequence_options_sql(increment: nil)).to eq('')
      end
    end

    context 'for :min' do
      it "includes 'MINVALUE' in the SQL if specified" do
        expect(dummy.sequence_options_sql(min: 1)).to eq(' MINVALUE 1')
        expect(dummy.sequence_options_sql(min: 2)).to eq(' MINVALUE 2')
      end

      it "does not include 'MINVALUE' in SQL if set to nil" do
        expect(dummy.sequence_options_sql(min: nil)).to eq('')
      end

      it "sets 'NO MINVALUE' if :min specified as false" do
        expect(dummy.sequence_options_sql(min: false)).to eq(' NO MINVALUE')
      end
    end

    context 'for :max' do
      it "includes 'MAXVALUE' in the SQL if specified" do
        expect(dummy.sequence_options_sql(max: 1)).to eq(' MAXVALUE 1')
        expect(dummy.sequence_options_sql(max: 2)).to eq(' MAXVALUE 2')
      end

      it "does not include 'MAXVALUE' in SQL if set to nil" do
        expect(dummy.sequence_options_sql(max: nil)).to eq('')
      end

      it "sets 'NO MAXVALUE' if :min specified as false" do
        expect(dummy.sequence_options_sql(max: false)).to eq(' NO MAXVALUE')
      end
    end

    context 'for :start' do
      it "includes 'START WITH' in SQL if specified" do
        expect(dummy.sequence_options_sql(start: 1)).to eq(' START WITH 1')
        expect(dummy.sequence_options_sql(start: 2)).to eq(' START WITH 2')
        expect(dummy.sequence_options_sql(start: 500)).to eq(' START WITH 500')
      end

      it "does not include 'START WITH' in SQL if specified as nil" do
        expect(dummy.sequence_options_sql(start: nil)).to eq('')
      end
    end

    context 'for :cache' do
      it "includes 'CACHE' in SQL if specified" do
        expect(dummy.sequence_options_sql(cache: 1)).to eq(' CACHE 1')
        expect(dummy.sequence_options_sql(cache: 2)).to eq(' CACHE 2')
        expect(dummy.sequence_options_sql(cache: 500)).to eq(' CACHE 500')
      end
    end

    context 'for :cycle' do
      it "includes 'CYCLE' option if specified" do
        expect(dummy.sequence_options_sql(cycle: true)).to eq(' CYCLE')
      end

      it "includes 'NO CYCLE' option if set as false" do
        expect(dummy.sequence_options_sql(cycle: false)).to eq(' NO CYCLE')
      end

      it "does not include 'CYCLE' statement if specified as nil" do
        expect(dummy.sequence_options_sql(cycle: nil)).to eq('')
      end
    end

    context 'for :owned_by' do
      it "includes 'OWNED BY table_name.column_name' in SQL if specified" do
        expect(dummy.sequence_options_sql(owned_by: 'users.counter')).to eq(' OWNED BY users.counter')
        expect(dummy.sequence_options_sql(owned_by: 'orders.number')).to eq(' OWNED BY orders.number')
      end

      it "does not include 'OWNED BY' in SQL if specified as false" do
        expect(dummy.sequence_options_sql(owned_by: false)).to eq('')
      end

      it "does not include 'OWNED BY' in SQL if specified as nil" do
        expect(dummy.sequence_options_sql(owned_by: nil)).to eq('')
      end
    end
  end

  context 'creating sequences' do
    context 'without options' do
      it 'generates the proper SQL' do
        expect(dummy.create_sequence_sql('things')).to eq('CREATE SEQUENCE things')
        expect(dummy.create_sequence_sql('blahs')).to eq('CREATE SEQUENCE blahs')
      end
    end

    context 'with options' do
      it 'includes options at the end' do
        output = 'CREATE SEQUENCE things INCREMENT BY 1 MINVALUE 1 MAXVALUE 2000000 START WITH 1 CACHE 5 CYCLE OWNED BY table_name.column_name'
        expect(dummy.create_sequence_sql('things', options.merge(start: 1))).to eq(output)
      end
    end
  end

  context 'altering sequences' do
    context 'without options' do
      it 'returns a blank SQL statement' do
        expect(dummy.change_sequence_sql('things')).to eq('')
        expect(dummy.change_sequence_sql('things', {})).to eq('')
        expect(dummy.change_sequence_sql('things', nil)).to eq('')
      end
    end

    context 'with options' do
      it 'includes options at the end' do
        output = 'ALTER SEQUENCE things INCREMENT BY 1 MINVALUE 1 MAXVALUE 2000000 RESTART WITH 1 CACHE 5 CYCLE OWNED BY table_name.column_name'
        expect(dummy.change_sequence_sql('things', options.merge(restart: 1))).to eq(output)
      end
    end
  end

  context 'dropping sequences' do
    it 'generates the proper SQL' do
      expect(dummy.drop_sequence_sql('users_seq')).to eq('DROP SEQUENCE users_seq')
      expect(dummy.drop_sequence_sql('items_seq')).to eq('DROP SEQUENCE items_seq')
    end
  end
end
