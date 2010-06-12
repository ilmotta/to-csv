require 'rubygems'
gem 'activerecord', '2.3.5'
require 'active_record'
require 'active_record/fixtures'

class ActiveRecordTestConnector
  FIXTURES_PATH = File.join(File.dirname(__FILE__), '..', 'fixtures')

  def self.setup
    setup_connection
    load_schema
    add_load_path FIXTURES_PATH
  end

  private

    def self.add_load_path(path)
      dep = defined?(ActiveSupport::Dependencies) ? ActiveSupport::Dependencies : ::Dependencies
      dep.load_paths.unshift path
    end

    def self.load_schema
      ActiveRecord::Base.silence do
        ActiveRecord::Migration.verbose = false
        load File.join(FIXTURES_PATH, 'schema.rb')
      end
    end

    def self.setup_connection
      configurations = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'database.yml'))
      ActiveRecord::Base.establish_connection configurations['sqlite3']
    end
end

