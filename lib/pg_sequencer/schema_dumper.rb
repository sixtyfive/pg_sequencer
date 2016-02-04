module PgSequencer
  module SchemaDumper
    extend ActiveSupport::Concern

    def tables_with_sequences(stream)
      super
      sequences
    end

    private
    def sequences
      sequence_statements = @connection.sequences.map do |sequence|
        statement_parts = [ ('create_sequence ') + sequence.name.inspect ]
        statement_parts << (':increment => ' + sequence.options[:increment].inspect)
        statement_parts << (':min => ' + sequence.options[:min].inspect)
        statement_parts << (':max => ' + sequence.options[:max].inspect)
        statement_parts << (':start => ' + sequence.options[:start].inspect)
        statement_parts << (':cache => ' + sequence.options[:cache].inspect)
        statement_parts << (':cycle => ' + sequence.options[:cycle].inspect)

        '  ' + statement_parts.join(', ')
      end

      @dump.final << sequence_statements.sort.join("\n").strip
    end
  end
end
