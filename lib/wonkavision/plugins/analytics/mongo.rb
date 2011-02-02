dir = File.dirname(__FILE__)
[
 '../../persistence/mongo',
 'persistence/mongo_store.rb'

].each {|lib|require File.join(dir,lib)}
