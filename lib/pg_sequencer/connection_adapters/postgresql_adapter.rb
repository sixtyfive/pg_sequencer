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
        # from PostgreSQL 8.4 (1.7.2009) this can be used (tested on 9.5.19 and 11.7)
        # unfortunatelly, schema.sequences not includes CACHE value, so we have to take more queries
        sequence_defs = select_all('SELECT * FROM information_schema.sequences')

        sequence_defs.collect do |row|
          name = row['sequence_name']

          options = {
            :increment => row['increment'].to_i,
            :min       => row['minimum_value'].to_i,
            :max       => row['maximum_value'].to_i,
            :start     => row['start_value'].to_i,
            :cache     => sequence_cache_value(name).to_i,
            :cycle     => row['cycle_option'] != 'NO'
          }

          SequenceDefinition.new(name, options)
        end
      end

      protected

      def sequence_cache_value(seq_name)
        # PostgreSQL v10 and above
        cache_details = select_one("SELECT * FROM pg_sequence WHERE seqrelid = '#{seq_name}'::regclass")
        return cache_details['seqcache']
      rescue ActiveRecord::StatementInvalid
        begin
          # lower versions
          row = select_one("SELECT * FROM #{seq_name}")
          return row['cache_value']
        rescue ActiveRecord::StatementInvalid
          return 1 # fallback to default PostgreSQL value
        end
      end

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
