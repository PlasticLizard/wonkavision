package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.core.Aggregate
import org.wonkavision.server.messages._
import org.wonkavision.core.Aggregation
import org.wonkavision.server.persistence.AggregationRepository

abstract trait AggregationActor extends Actor {
	import context._

	val aggregation : Aggregation
	val repo : AggregationRepository

	def receive = {
		case query : AggregateQuery => sender ! executeQuery(query)
		case add : AddAggregate => repo.put(aggregation.createAggregate(add.dimensions, add.data))
		case add : AddAggregates => repo.put(add.dimensions, add.data.map(d => aggregation.createAggregate(add.dimensions, d)))
		case del : DeleteAggregate => repo.delete(del.dimensions, del.key)
		case purge : PurgeDimensionSet => repo.purge(purge.dimensions)
		case purge : PurgeAggregation => repo.purgeAll()
	}

	def executeQuery(query : AggregateQuery) : Iterable[Aggregate] = repo.select(query)
}