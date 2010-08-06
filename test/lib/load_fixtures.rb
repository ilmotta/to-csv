require File.expand_path(File.join(File.dirname(__FILE__), 'activerecord_test_connector'))

# setup the connection
ActiveRecordTestConnector.setup

# load all fixtures
Fixtures.create_fixtures(ActiveRecordTestConnector::FIXTURES_PATH, ActiveRecord::Base.connection.tables)

require 'to_csv'

