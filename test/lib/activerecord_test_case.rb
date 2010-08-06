require File.expand_path(File.join(File.dirname(__FILE__), 'activerecord_test_connector'))

class ActiveRecordTestCase < Test::Unit::TestCase
  if defined? ActiveSupport::Testing::SetupAndTeardown
    include ActiveSupport::Testing::SetupAndTeardown
  end

  if defined? ActiveRecord::TestFixtures
    include ActiveRecord::TestFixtures
  end

  self.fixture_path = ActiveRecordTestConnector::FIXTURES_PATH
  self.use_transactional_fixtures = true

  def self.fixtures(*args)
    super
  end
end

ActiveRecordTestConnector.setup

