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
		case query : AggregationQuery => sender ! executeQuery(query)
		case add : AddAggregate => repo.put(add.dimensions, add.key, add.agg)
		case add : AddAggregates => repo.put(add.dimensions, add. aggs)
		case del : DeleteAggregate => repo.delete(del.dimensions, del.key)
		case purge : PurgeDimensionSet => repo.purge(purge.dimensions)
		case purge : Purge => repo.purgeAll()
	}

	def executeQuery(query : AggregationQuery) : Iterable[Aggregate] = repo.select(query)
}