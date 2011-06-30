require "test_helper"
require "test_helper/em_mongo"

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
        collection.remove({})#nuke all keys
        
        collection.insert('hello' => 'world')
        found = @store.find('hello' => 'world')[0]
        assert_equal found["hello"], "world"

        EM.stop  
      end 
    end 

    should "find a record asynchronously" do
      EM.synchrony do
        Connection.connect :database => 'wonkavision_test'
        collection = @store.collection
        collection.remove({})#nuke all keys

        collection.insert('hello' => 'world')
        @store.afind('hello'=>'world') do |results|
          assert_equal results[0]["hello"], "world"
          EM.stop          
        end
      end
    end

    should "update a record" do
      EM.synchrony do
        Connection.connect(:database => 'wonkavision_test')
        collection = @store.collection
        collection.remove({})#nuke all keys in collection

        obj_id = collection.insert('hello' => 'world')
        @store.update({'hello' => 'world'}, {'hello' => 'newworld'})

        new_obj = collection.first({'_id' => obj_id})
        assert_equal new_obj['hello'], 'newworld'

        EM.stop
      end
    end

  end

end
