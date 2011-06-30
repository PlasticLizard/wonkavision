require "wonkavision/analytics/persistence/mongo"

Wonkavision::Analytics::Persistence::Mongo.connect(
	:database => 'wonkavision_test'	
)

module ActiveSupport
  class TestCase
    
    def setup
    end

    def teardown
      Wonkavision::Analytics::Persistence::Mongo.database.collections.each do |coll|
        coll.drop unless coll.name =~ /(.*\.)?system\..*/
      end
    end
  
  end
end