package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.server.Aggregate
import org.wonkavision.server.messages._
import org.wonkavision.core.Aggregation
import org.wonkavision.server.persistence.AggregationRepository

abstract trait AggregationActor extends Actor {
	import context._

	val aggregation : Aggregation
	val repo : AggregationRepository

	def receive = {
		case query : AggregationQuery => {
			sender ! executeQuery(query)
		}
	}

	def executeQuery(query : AggregationQuery) : Iterable[Aggregate] = repo.select(query)
}