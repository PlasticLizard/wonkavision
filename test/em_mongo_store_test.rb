require "test_helper"
require "wonkavision/analytics/persistence/em_mongo"


class EMMongoStoreTest < ActiveSupport::TestCase
  EMMongoStore = Wonkavision::Analytics::Persistence::EMMongoStore
  Connection = Wonkavision::Analytics::Persistence::EMMongo

  context "MongoStore" do
    setup do
      @store = EMMongoStore.new(Wonkavision::Analytics::Facts)
    end

    should "make a connection and set the database" do
      EM.synchrony do
        Connection.connect(:database => 'wonkavision_test')
        assert Connection.database.is_a? EM::Mongo::Database

        EM.stop
      end  
    end 
    
    should "find a record" do
      EM.synchrony do
        Connection.connect :database => 'wonkavision_test'
        collection = @store.collection
        collection.remove({})
        
        collection.insert('hello' => 'world')
        found = @store.find('hello' => 'world')[0]
        assert_equal found["hello"], "world"

        EM.stop  
      end 
    end 

    should "finda and modify a record" do
      EM.synchrony do
        Connection.connect :database => 'wonkavision_test'
        collection = @store.collection
        collection.remove({})

        collection.insert('hello' => 'world')
        found = collection.find_and_modify(:query => {'hello' => 'world'}, :update => {"$set" => {'hello' => 'dlrow'}})
        assert_equal 'world', found['hello']
        assert_equal 'dlrow', collection.first['hello']

        EM.stop
      end
    end

    should "update a record" do
      EM.synchrony do
        Connection.connect(:database => 'wonkavision_test')
        collection = @store.collection
        collection.remove({})

        obj_id = collection.insert('hello' => 'world')
        @store.update({'hello' => 'world'}, {'hello' => 'newworld'})

        new_obj = collection.first({'_id' => obj_id})
        assert_equal new_obj['hello'], 'newworld'

        EM.stop
      end
    end

  end

end
