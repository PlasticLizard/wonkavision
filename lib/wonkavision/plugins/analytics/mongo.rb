dir = File.dirname(__FILE__)
[
 '../../persistence/mongo',
 '../../mongo_aggregation',
 'mongo_aggregation',
 'persistence/mongo_store.rb'

].each {|lib|require File.join(dir,lib)}
