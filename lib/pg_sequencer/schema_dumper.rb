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

# Used to add `create_sequence(...)` in `db/schema.rb` after creating tables
module PgSequencer
  module SchemaDumper
    extend ActiveSupport::Concern

    def tables(stream)

      unless sequences_not_from_create_table.empty?
        stream.puts
        create_sequences(stream, sequences_not_from_create_table) unless sequences_not_from_create_table.empty?
        stream.puts
      end

      super(stream)

      unless sequences_from_create_table.empty?
        stream.puts
        # sequences must go after tables to correctly find sequences created along with them
        create_sequences(stream, sequences_from_create_table)
        stream.puts
      end
    end

    private

    def create_sequences(stream, sequences)
      sequence_statements = sequences.map do |sequence|
        statement_parts = ['create_sequence ' + sequence.name.inspect]
        statement_parts << (':increment => ' + sequence.options[:increment].inspect)
        statement_parts << (':min => ' + sequence.options[:min].inspect)
        statement_parts << (':max => ' + sequence.options[:max].inspect)
        statement_parts << (':start => ' + sequence.options[:start].inspect)
        statement_parts << (':cache => ' + sequence.options[:cache].inspect)
        statement_parts << (':cycle => ' + sequence.options[:cycle].inspect)

        '  ' + statement_parts.join(', ')
      end

      stream.puts sequence_statements.sort.join("\n")
    end

    def sequences_from_create_table
      @connection.sequences.select { |sq| sq.name.ends_with?('_id_seq') }
    end

    def sequences_not_from_create_table
      @connection.sequences.to_a - sequences_from_create_table.to_a
    end
  end
end
