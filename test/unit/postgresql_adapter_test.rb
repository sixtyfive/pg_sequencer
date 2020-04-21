# frozen_string_literal: true

# Copyright (c) 2016 Code42, Inc.

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
require 'helper'
require 'pg_sequencer/connection_adapters/postgresql_adapter'

class TestAdapter
  include PgSequencer::ConnectionAdapters::PostgreSQLAdapter
  attr_reader :executed_statements, :existing_sequence_names
  def initialize(existing_sequence_names =[])
    @existing_sequence_names = existing_sequence_names
    @executed_statements = []
  end

  def execute(sql_statement)
    @executed_statements << sql_statement
  end

  def select_all(_statement)
    existing_sequence_names.collect { |name| { 'sequence_name' => name } }
  end
end

class PostgreSQLAdapterTest < ActiveSupport::TestCase
  attr_reader :adapter, :sequence_name, :options
  setup do
    @adapter = TestAdapter.new
    @sequence_name = 'test_id_seq'
    @options = {
      increment: 1,
      start: 4,
      min: 1,
      max: 2_000_000,
      cache: 5,
      cycle: true
    }
  end

  context 'generating sequence option SQL' do
    should "include 'INCREMENT BY' in the SQL if it is specified" do
      assert_equal(' INCREMENT BY 1', adapter.sequence_options_sql(increment: 1))
      assert_equal(' INCREMENT BY 2', adapter.sequence_options_sql(increment: 2))
      assert_equal('', adapter.sequence_options_sql(increment: nil))
    end

    should "include 'MINVALUE' in the SQL if specified" do
      assert_equal(' MINVALUE 1', adapter.sequence_options_sql(min: 1))
      assert_equal(' MINVALUE 2', adapter.sequence_options_sql(min: 2))
      assert_equal('', adapter.sequence_options_sql(min: nil))
      assert_equal(' NO MINVALUE', adapter.sequence_options_sql(min: false))
    end

    should "include 'MAXVALUE' in the SQL if specified" do
      assert_equal(' MAXVALUE 1', adapter.sequence_options_sql(max: 1))
      assert_equal(' MAXVALUE 2', adapter.sequence_options_sql(max: 2))
      assert_equal('', adapter.sequence_options_sql(max: nil))
      assert_equal(' NO MAXVALUE', adapter.sequence_options_sql(max: false))
    end

    should "include 'START WITH' in SQL if specified" do
      assert_equal(' START WITH 1', adapter.sequence_options_sql(start: 1))
      assert_equal(' START WITH 2', adapter.sequence_options_sql(start: 2))
      assert_equal('', adapter.sequence_options_sql(start: nil))
    end

    should "include 'CACHE' in SQL if specified" do
      assert_equal(' CACHE 1', adapter.sequence_options_sql(cache: 1))
      assert_equal(' CACHE 2', adapter.sequence_options_sql(cache: 2))
      assert_equal('', adapter.sequence_options_sql(cache: nil))
    end

    context 'for :cycle' do
      should "include 'CYCLE' option if specified" do
        assert_equal(' CYCLE', adapter.sequence_options_sql(cycle: true))
        assert_equal(' NO CYCLE', adapter.sequence_options_sql(cycle: false))
        assert_equal('', adapter.sequence_options_sql(cycle: nil))
      end
    end

    should 'include all options' do
      assert_equal(' INCREMENT BY 1 MINVALUE 1 MAXVALUE 2000000 START WITH 4 CACHE 5 CYCLE',
                   adapter.sequence_options_sql(options))
    end
    # end of context 'generating sequence option SQL'
  end

  context 'creating sequences' do
    context 'without options' do
      should 'generate the proper SQL' do
        assert_equal('CREATE SEQUENCE things', adapter.create_sequence_sql('things'))
        assert_equal('CREATE SEQUENCE blahs', adapter.create_sequence_sql('blahs'))
      end
    end

    context 'with options' do
      should 'include options at the end' do
        assert_equal('CREATE SEQUENCE things INCREMENT BY 1 MINVALUE 1 MAXVALUE 2000000 START WITH 4 CACHE 5 CYCLE',
                     adapter.create_sequence_sql('things', options))
      end
    end
  end

  context 'altering sequences' do
    context 'without options' do
      should 'return a blank SQL statement' do
        assert_equal('', adapter.change_sequence_sql('things'))
        assert_equal('', adapter.change_sequence_sql('things', {}))
        assert_equal('', adapter.change_sequence_sql('things', nil))
      end
    end

    context 'with options' do
      should 'include options at the end' do
        assert_equal('ALTER SEQUENCE things INCREMENT BY 1 MINVALUE 1 MAXVALUE 2000000 RESTART WITH 1 CACHE 5 CYCLE',
                     adapter.change_sequence_sql('things', options.merge(restart: 1)))
      end
    end
  end

  context 'dropping sequences' do
    should 'generate the proper SQL' do
      assert_equal('DROP SEQUENCE seq_users', adapter.drop_sequence_sql('seq_users'))
      assert_equal('DROP SEQUENCE seq_items', adapter.drop_sequence_sql('seq_items'))
    end
  end

  context 'getting sequences from DB' do
    # TODO:  depends on version of PostgreSQL, so we have to mock direct calls to DB
  end

  context 'executing common situations' do
    should 'create sequence' do
      assert_equal [], adapter.executed_statements

      adapter.create_sequence(sequence_name, options)

      expected_statements = [
        "CREATE SEQUENCE #{sequence_name} INCREMENT BY 1 MINVALUE 1 MAXVALUE 2000000 START WITH 4 CACHE 5 CYCLE"
      ]
      assert_equal expected_statements, adapter.executed_statements
    end

    should 'alter sequence' do
      assert_equal [], adapter.executed_statements

      adapter.change_sequence(sequence_name, options)

      expected_statements = [
        "ALTER SEQUENCE #{sequence_name} INCREMENT BY 1 MINVALUE 1 MAXVALUE 2000000 CACHE 5 CYCLE"
      ]
      assert_equal expected_statements, adapter.executed_statements
    end

    should 'drop sequence' do
      assert_equal [], adapter.executed_statements

      adapter.drop_sequence(sequence_name)

      expected_statements = ["DROP SEQUENCE #{sequence_name}"]
      assert_equal expected_statements, adapter.executed_statements
    end
  end

  context 'when sequence with same name already exists' do
    should 'skip creation by default' do
      adapter = TestAdapter.new([sequence_name])
      assert_equal [], adapter.executed_statements

      adapter.create_sequence(sequence_name, options)

      assert_equal [], adapter.executed_statements
    end

    should 'drop it if :drop_if_exists is set to true' do
      adapter = TestAdapter.new([sequence_name])
      assert_equal [], adapter.executed_statements

      adapter.create_sequence(sequence_name, options.merge(drop_if_exists: true))

      expected_statements = [
        "DROP SEQUENCE #{sequence_name}",
        "CREATE SEQUENCE #{sequence_name} INCREMENT BY 1 MINVALUE 1 MAXVALUE 2000000 START WITH 4 CACHE 5 CYCLE"
      ]
      assert_equal expected_statements, adapter.executed_statements
    end
  end
end
