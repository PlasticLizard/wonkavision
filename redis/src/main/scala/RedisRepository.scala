//Portions copied from Akka Durable Mailbox impl
package org.wonkavision.server.persistence

import org.wonkavision.server.Wonkavision
import org.wonkavision.core.exceptions.WonkavisionException

import com.redis._
import akka.event.Logging

class RedisRepository(val wonkavision : Wonkavision) {

	val settings = new WonkavisionRedisSettings(wonkavision.config)
	val log = Logging(wonkavision.system, "WonkavisionRedisRepository")
	@volatile
	private var clients = connect()

	private def connect() = {
    	new RedisClientPool(settings.Hostname, settings.Port)
  	}

  	protected def exec[T](body : RedisClient => T) : T = {
  		withErrorHandling {
  			clients.withClient { client =>
  				body(client)
  			}
  		}
  	}

  	protected def withErrorHandling[T](body: => T): T = {
	    try {
	      body
	    } catch {
	     	case e: RedisConnectionException => {
	       		clients = connect()
	        	body
	      	}
	      	case e: Exception => {
				val error = new WonkavisionRedisException("Could not connect to Redis server, due to: " + e.getMessage)
        		log.error(error, error.getMessage)
        		throw error
	 		}
	 	}
 	}
 }

 class WonkavisionRedisException(message : String) extends WonkavisionException(message)