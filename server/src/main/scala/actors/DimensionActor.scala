package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.server.messages._
import org.wonkavision.core.Dimension
import org.wonkavision.server.DimensionMember
import org.wonkavision.server.persistence.DimensionReader


abstract trait DimensionActor extends Actor {
	import context._

	val dimension : Dimension

	def receive = {
		case query : DimensionMemberQuery => {	
			sender ! executeQuery(query)
		}
	}

	def executeQuery(query : DimensionMemberQuery) : DimensionMembers
}

abstract trait DimensionReaderActor
	extends DimensionActor {

		val reader : DimensionReader

		def executeQuery(query : DimensionMemberQuery) = {
			DimensionMembers(dimension, reader.select(query), query.hasFilter)
		}
}