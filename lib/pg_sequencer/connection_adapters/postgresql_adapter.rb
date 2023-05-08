# frozen_string_literal: true

module PgSequencer
  module ConnectionAdapters
    # This module enhances ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    # https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/postgresql_adapter.rb
    module PostgresqlAdapter
      # Example usage:
      #
      #   create_sequence "user_seq",
      #     increment: 1,
      #     min: (1|false),
      #     max: (20000|false),
      #     start: 1,
      #     cache: 5,
      #     cycle: true,
      #     owned_by: ("table_name.column_name"|nil),
      #
      def create_sequence(name, options = {})
        execute create_sequence_sql(name, options)
      end

      # Example usage:
      #
      #   change_sequence "user_seq",
      #     increment: 1,
      #     min: (1|false),
      #     max: (20000|false),
      #     restart: 1,
      #     cache: 5,
      #     cycle: true,
      #     owned_by: ("table_name.column_name"|nil),
      #
      def change_sequence(name, options = {})
        execute change_sequence_sql(name, options)
      end

      # Example usage:
      #
      #   drop_sequence "user_seq"
      #
      def drop_sequence(name)
        execute drop_sequence_sql(name)
      end

      # Example SQL:
      #
      #   CREATE [ TEMPORARY | TEMP ] SEQUENCE [ IF NOT EXISTS ] name [ INCREMENT [ BY ] increment ]
      #     [ MINVALUE minvalue | NO MINVALUE ] [ MAXVALUE maxvalue | NO MAXVALUE ]
      #     [ START [ WITH ] start ] [ CACHE cache ] [ [ NO ] CYCLE ]
      #     [ OWNED BY { table_name.column_name | NONE } ]
      #
      def create_sequence_sql(name, options = {})
        options.delete(:restart)
        "CREATE SEQUENCE #{name}#{sequence_options_sql(options)}"
      end

      # Example SQL:
      #
      #   ALTER SEQUENCE [ IF EXISTS ] name [ INCREMENT [ BY ] increment ]
      #     [ MINVALUE minvalue | NO MINVALUE ] [ MAXVALUE maxvalue | NO MAXVALUE ]
      #     [ START [ WITH ] start ]
      #     [ RESTART [ [ WITH ] restart ] ]
      #     [ CACHE cache ] [ [ NO ] CYCLE ]
      #     [ OWNED BY { table_name.column_name | NONE } ]
      #
      def change_sequence_sql(name, options = {})
        return '' if options.blank?

        options.delete(:start)
        "ALTER SEQUENCE #{name}#{sequence_options_sql(options)}"
      end

      # Example SQL:
      #
      #   DROP SEQUENCE [ IF EXISTS ] name [, ...] [ CASCADE | RESTRICT ]
      #
      def drop_sequence_sql(name)
        "DROP SEQUENCE #{name}"
      end

      def sequence_options_sql(options = {}) # rubocop:disable Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/CyclomaticComplexity
        sql = ''
        sql += increment_option_sql(options) if options[:increment] || options[:increment_by]
        sql += min_option_sql(options)
        sql += max_option_sql(options)
        sql += start_option_sql(options) if options[:start] || options[:start_with]
        sql += restart_option_sql(options) if options[:restart] || options[:restart_with]
        sql += cache_option_sql(options) if options[:cache]
        sql += cycle_option_sql(options)
        sql += owned_option_sql(options) if options[:owned_by]
        sql
      end

      def sequences
        select_sequence_names.map do |sequence_name|
          sequence = select_sequence(sequence_name)
          owner = select_sequence_owners(sequence_name).first

          options = options_from_sequence(sequence, owner)

          SequenceDefinition.new(sequence_name, options)
        end
      end

    protected

      def owner_is_primary_key(owner)
        owner && owner[:column] == primary_key(owner[:table])
      end

      def owned_by(owner)
        owner ? "#{owner[:table]}.#{owner[:column]}" : nil
      end

      def find_first(sequence, keys)
        v = sequence.values_at(*keys)
        v.compact![0]
      end

      def cycle_for_sequence(sequence)
        find_first(sequence, %w[seqcycle is_cycled]) == 't' || sequence['cycle_option'] == 'YES'
      end

      def options_from_sequence(sequence, owner)
        {
          increment: find_first(sequence, ['seqincrement', :increment, 'increment']).to_i,
          min: find_first(sequence, %w[seqmin min_value minimum_value]).to_i,
          max: find_first(sequence, %w[seqmax max_value maximum_value]).to_i,
          start: find_first(sequence, %w[seqstart start_value]).to_i,
          cache: find_first(sequence, %w[seqcache cache_value]).to_i,
          cycle: cycle_for_sequence(sequence),
          owned_by: owned_by(owner),
          owner_is_primary_key: owner_is_primary_key(owner),
        }
      end

      # Values for all sequences:
      # --------------+--------------------
      # relname       | some_seq
      def select_sequence_names
        sql = <<~SQL.squish
          SELECT c.relname FROM pg_class c
          WHERE c.relkind = 'S' ORDER BY c.relname ASC
        SQL

        select_all(sql).pluck('relname')
      end

      def select_sequence(sequence_name)
        if postgresql_version > 100_000
          select_one("SELECT * FROM pg_sequence WHERE seqrelid='#{sequence_name}'::regclass")
        else
          select_one("SELECT increment_by AS seqincrement, min_value AS seqmin, max_value AS seqmax, start_value AS seqstart, cache_value AS seqcache, is_cycled AS seqcycle FROM #{sequence_name}")
        end
      end

      # Values for owners of a sequence:
      # --------------+-------------
      # sequence_name | order_number_seq
      # table_name    | orders
      # column_name   | order_number
      # sch           | public
      def select_sequence_owners(sequence_name) # rubocop:disable Metrics/MethodLength
        sql = <<~SQL.squish
          SELECT s.relname AS sequence_name, t.relname AS table_name, a.attname AS column_name, n.nspname AS sch
          FROM pg_class s
          JOIN pg_depend d ON d.objid = s.oid AND d.classid = 'pg_class'::regclass AND d.refclassid = 'pg_class'::regclass
          JOIN pg_class t ON t.oid = d.refobjid
          JOIN pg_namespace n ON n.oid = t.relnamespace
          JOIN pg_attribute a ON a.attrelid = t.oid AND a.attnum = d.refobjsubid
          WHERE s.relkind = 'S' AND d.deptype = 'a'
          AND s.relname = '#{sequence_name}'
        SQL

        select_all(sql).map do |row|
          {
            sequence: row['sequence_name'],
            table: row['table_name'],
            column: row['column_name'],
            sch: row['sch'],
          }
        end
      end

      def increment_option_sql(options = {})
        " INCREMENT BY #{options[:increment] || options[:increment_by]}"
      end

      def min_option_sql(options = {})
        case options[:min]
        when nil then ''
        when false then ' NO MINVALUE'
        else " MINVALUE #{options[:min]}"
        end
      end

      def max_option_sql(options = {})
        case options[:max]
        when nil then ''
        when false then ' NO MAXVALUE'
        else " MAXVALUE #{options[:max]}"
        end
      end

      def restart_option_sql(options = {})
        " RESTART WITH #{options[:restart] || options[:restart_with]}"
      end

      def start_option_sql(options = {})
        " START WITH #{options[:start] || options[:start_with]}"
      end

      def cache_option_sql(options = {})
        " CACHE #{options[:cache]}"
      end

      def cycle_option_sql(options = {})
        case options[:cycle]
        when nil then ''
        when false then ' NO CYCLE'
        else ' CYCLE'
        end
      end

      def owned_option_sql(options = {})
        case options[:owned_by]
        when nil, false then ''
        else " OWNED BY #{options[:owned_by]}"
        end
      end
    end
  end
end
