module PgSequencer
  module ConnectionAdapters

    class SequenceDefinition < Struct.new(:name, :options)
    end

    module PostgreSQLAdapter
      def create_sequence(name, options = {})
        execute create_sequence_sql(name, options)
      end

      def drop_sequence(name)
        execute drop_sequence_sql(name)
      end

      def change_sequence(name, options = {})
        execute change_sequence_sql(name, options)
      end

      # CREATE [ TEMPORARY | TEMP ] SEQUENCE name [ INCREMENT [ BY ] increment ]
      #     [ MINVALUE minvalue | NO MINVALUE ] [ MAXVALUE maxvalue | NO MAXVALUE ]
      #     [ START [ WITH ] start ] [ CACHE cache ] [ [ NO ] CYCLE ]
      #
      # create_sequence "seq_user",
      #   :increment => 1,
      #   :min       => (1|false),
      #   :max       => (20000|false),
      #   :start     => 1,
      #   :cache     => 5,
      #   :cycle     => true
      def create_sequence_sql(name, options = {})
        options.delete(:restart)
        "CREATE SEQUENCE #{name}#{sequence_options_sql(options)}"
      end

      def drop_sequence_sql(name)
        "DROP SEQUENCE #{name}"
      end

      def change_sequence_sql(name, options = {})
        return "" if options.blank?
        options.delete(:start)
        "ALTER SEQUENCE #{name}#{sequence_options_sql(options)}"
      end

      def sequence_options_sql(options = {})
        sql = ""
        sql << increment_option_sql(options)  if options[:increment] or options[:increment_by]
        sql << min_option_sql(options)
        sql << max_option_sql(options)
        sql << start_option_sql(options)      if options[:start]    or options[:start_with]
        sql << restart_option_sql(options)    if options[:restart]  or options[:restart_with]
        sql << cache_option_sql(options)      if options[:cache]
        sql << cycle_option_sql(options)
        sql
      end

      def sequences
        # sequence_temp=# select * from temp;
        # -[ RECORD 1 ]-+--------------------
        # sequence_name | temp
        # last_value    | 7
        # start_value   | 1
        # increment_by  | 1
        # max_value     | 9223372036854775807
        # min_value     | 1
        # cache_value   | 1
        # log_cnt       | 26
        # is_cycled     | f
        # is_called     | t
        sequence_names = select_all(<<-SQL).map { |row| row['relname'] }
          SELECT seq.relname FROM pg_class AS seq
          JOIN pg_namespace ns ON (seq.relnamespace=ns.oid)
          WHERE seq.relkind = 'S' AND NOT EXISTS (SELECT * FROM pg_depend WHERE objid=seq.oid AND deptype='a')
          AND pg_table_is_visible(seq.oid) ORDER BY seq.relname;
        SQL

        all_sequences = []

        sequence_names.each do |sequence_name|
          row = select_one("SELECT * FROM #{sequence_name}")

          options = {
            :increment => row['increment_by'].to_i,
            :min       => row['min_value'].to_i,
            :max       => row['max_value'].to_i,
            :start     => row['start_value'].to_i,
            :cache     => row['cache_value'].to_i,
            :cycle     => row['is_cycled'] == 't'
          }

          all_sequences << SequenceDefinition.new(sequence_name, options)
        end

        all_sequences
      end

      protected
      def increment_option_sql(options = {})
        " INCREMENT BY #{options[:increment] || options[:increment_by]}"
      end

      def min_option_sql(options = {})
        case options[:min]
        when nil then ""
        when false then " NO MINVALUE"
        else " MINVALUE #{options[:min]}"
        end
      end

      def max_option_sql(options = {})
        case options[:max]
        when nil then ""
        when false then " NO MAXVALUE"
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
        when nil then ""
        when false then " NO CYCLE"
        else " CYCLE"
        end
      end

    end
  end
end

# todo: add JDBCAdapter?
[:PostgreSQLAdapter].each do |adapter|
  begin
    ActiveRecord::ConnectionAdapters.const_get(adapter).class_eval do
      include PgSequencer::ConnectionAdapters::PostgreSQLAdapter
    end
  rescue
  end
end
