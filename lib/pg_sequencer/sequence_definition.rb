# frozen_string_literal: true

module PgSequencer
  # Abstract representation of any adapter's sequence
  class SequenceDefinition
    attr_accessor :name, :options

    def initialize(name, options = {})
      @name = name
      @options = options
    end
  end
end
