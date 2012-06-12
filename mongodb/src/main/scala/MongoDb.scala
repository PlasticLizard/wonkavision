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
    	MongoConnection(settings.Hostname, settings.Port)
  	}

  	def collection(collectionName : String) = db(collectionName)
 }

