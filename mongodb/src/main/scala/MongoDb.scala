//Portions copied from Akka Durable Mailbox impl
package org.wonkavision.mongodb

import org.wonkavision.core.exceptions.WonkavisionException

import akka.event.Logging
import akka.dispatch.{ExecutionContext, Promise, Future}
import akka.actor.ActorSystem

import com.mongodb.casbah.Imports._


class MongoDb(val system : ActorSystem) {

	val settings = new WonkavisionMongoDbSettings(system.settings.config)
	val log = Logging(system, "WonkavisionMongoDbRepository")
	

	@volatile
	private var client = connect()
	lazy private val db = client(settings.DatabaseName)

	private def connect() = {
    	//new RedisClientPool(settings.Hostname, settings.Port)
    	MongoConnection(settings.Hostname, settings.Port)
  	}

  	def collection(collectionName : String) = db(collectionName)
  	

  // 	protected def withErrorHandling[T](body: => T): T = {
	 //    try {
	 //      body
	 //    } catch {
	 //     	case e: RedisConnectionException => {
	 //       		clients = connect()
	 //        	body
	 //      	}
	 //      	case e: Exception => {
		// 		val error = new WonkavisionRedisException("Could not connect to Redis server, due to: " + e.getMessage)
  //       		log.error(error, error.getMessage)
  //       		throw error
	 // 		}
	 // 	}
 	// }
 }

 //class WonkavisionRedisException(message : String) extends WonkavisionException(message)