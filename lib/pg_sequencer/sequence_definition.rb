# frozen_string_literal: true

module PgSequencer
  class SequenceDefinition
    attr_accessor :name, :options

    def initialize(name, options = {})
      @name = name
      @options = options
    end
  end
end
