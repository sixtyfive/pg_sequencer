# frozen_string_literal: true

module PgSequencer
  module RollbackSupport
    extend ActiveSupport::Concern

    included do
      %i[create_sequence drop_sequence change_sequence].each do |m|
        self::ReversibleAndIrreversibleMethods.tap { |x| x << m unless x.include?(m) }
      end
    end

    def create_sequence(*args)
      warn 'recorded'
      record(:create_sequence, args)
    end

    def drop_sequence(*args)
      warn 'recorded'
      record(:drop_sequence, args)
    end

    def change_sequence(*args)
      warn 'recorded'
      record(:change_sequence, args)
    end

    def invert_create_sequence(args)
      warn 'invert'
      [:drop_sequence, [args.first]]
    end

    def invert_drop_sequence(args)
      warn 'invert'
      [:create_sequence, args]
    end

    #    def invert_change_sequence(args)
    #      [:invert_change_sequence, args]
    #      raise ActiveRecord::IrreversibleMigration, 'change_sequence is irreversible.'
    #    end
  end
end
