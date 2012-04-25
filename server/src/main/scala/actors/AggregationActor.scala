package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.server.Aggregate
import org.wonkavision.server.messages._
import org.wonkavision.core.Aggregation
import org.wonkavision.server.persistence.AggregationReader

abstract trait AggregationActor extends Actor {
	import context._

	val aggregation : Aggregation

	def receive = {
		case query : AggregationQuery => {
			sender ! executeQuery(query)
		}
	}

	def executeQuery(query : AggregationQuery) : Iterable[Aggregate]
}

abstract trait AggregationReaderActor
	extends AggregationActor {

		val reader : AggregationReader

		def executeQuery(query : AggregationQuery) = reader.select(query)

}

