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
  class Railtie < Rails::Railtie
    initializer "pg_sequencer.load_adapter" do
      ActiveSupport.on_load :active_record do
        require 'pg_sequencer/connection_adapters/postgresql_adapter'

        ActiveRecord::ConnectionAdapters.module_eval do
          include PgSequencer::ConnectionAdapters::PostgreSQLAdapter
        end

        ActiveRecord::SchemaDumper.class_eval do
          prepend PgSequencer::SchemaDumper
        end

      end

  #     if defined?(ActiveRecord::Migration::CommandRecorder)
  #       ActiveRecord::Migration::CommandRecorder.class_eval do
  #         include PgSequencer::Migration::CommandRecorder
  #       end
  #     end
  #
  #     # PgSequencer::Adapter.load!
  #   end

    end # initializer
  end
end
