require 'helper'

class SchemaDumperTest < Test::Unit::TestCase

  class SequenceDefinition < Struct.new(:name, :options); end

  class MockConnection
    attr_accessor :sequences

    def initialize(sequences = [])
      @sequences = sequences
    end

  end

  class MockStream
    attr_accessor :output
    def initialize; @output = []; end
    def puts(str = ""); @output << str; end
    def to_s; @output.join("\n"); end
  end

  class MockSchemaDumper
    def initialize(connection, dump)
      @connection = connection
      @dump = dump
    end

    def self.dump(conn, stream)
      new(conn).dump(stream)
    end

    def header(stream)
      stream.puts '# Fake Schema Header'
    end

    def tables(stream)
      stream.puts '# (No Tables)'
    end

    def dump(stream)
      header(stream)
      tables(stream)
      trailer(stream)
      stream
    end

    def trailer(stream)
      stream.puts '# Fake Schema Trailer'
    end

    prepend PgSequencer::SchemaDumper
  end

  context "dumping the schema" do
    setup do
      @options = {
        :increment => 1,
        :min       => 1,
        :max       => 2_000_000,
        :start     => 1,
        :cache     => 5,
        :cycle     => true
      }

      @stream = MockStream.new
      @dump = OpenStruct.new(final: "")
    end

    should "output all sequences correctly" do
      sequences = ['seq_t_user', 'seq_t_item'].map do |name|
        SequenceDefinition.new(name, @options)
      end

      @conn = MockConnection.new(sequences)

      expected_stream_output = <<-SCHEMAEND
# Fake Schema Header
# (No Tables)
# Fake Schema Trailer
SCHEMAEND

      expected_dump_final_output = <<-SCHEMAEND
  create_sequence "seq_t_item", :increment => 1, :min => 1, :max => 2000000, :start => 1, :cache => 5, :cycle => true
  create_sequence "seq_t_user", :increment => 1, :min => 1, :max => 2000000, :start => 1, :cache => 5, :cycle => true
SCHEMAEND

      MockSchemaDumper.new(@conn, @dump).dump(@stream)
      assert_equal(expected_stream_output.strip, @stream.to_s)
      assert_equal(expected_dump_final_output.strip, @dump.final.strip)
    end

    context "when min specified as false" do
      setup do
        sequences = ['seq_t_user', 'seq_t_item'].map do |name|
          SequenceDefinition.new(name, @options.merge(:min => false))
        end
        @conn = MockConnection.new(sequences)
      end

      should "properly quote false values in schema output" do
        expected_stream_output = <<-SCHEMAEND
# Fake Schema Header
# (No Tables)
# Fake Schema Trailer
SCHEMAEND

      expected_dump_final_output = <<-SCHEMAEND
  create_sequence "seq_t_item", :increment => 1, :min => false, :max => 2000000, :start => 1, :cache => 5, :cycle => true
  create_sequence "seq_t_user", :increment => 1, :min => false, :max => 2000000, :start => 1, :cache => 5, :cycle => true
SCHEMAEND

      MockSchemaDumper.new(@conn, @dump).dump(@stream)
      assert_equal(expected_stream_output.strip, @stream.to_s)
      assert_equal(expected_dump_final_output.strip, @dump.final.strip)
      end
    end
  end
end
