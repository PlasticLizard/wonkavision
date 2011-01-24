dir = File.dirname(__FILE__)
[
 '../../persistence/mongo',
 '../../mongo_aggregation',
 'mongo_aggregation'

].each {|lib|require File.join(dir,lib)}
