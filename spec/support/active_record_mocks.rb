# frozen_string_literal: true

class MockConnection
  attr_accessor :sequences

  def initialize(sequences = [])
    @sequences = sequences
  end
end

class MockStream
  attr_accessor :output

  def initialize
    @output = []
  end

  def puts(str = '')
    @output << str
  end

  def to_s
    @output.join("\n")
  end
end

class MockSchemaDumper
  prepend PgSequencer::SchemaDumper
  def self.dump(conn, stream)
    new(conn).dump(stream)
  end

  def initialize(connection)
    @connection = connection
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
end
