package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.server.messages._
import org.wonkavision.core.Cube
import org.wonkavision.server.Aggregate

import akka.dispatch.{Await, Future}
import akka.pattern.{ask, pipe}
import akka.util.Timeout
import akka.util.duration._



class CubeActor(val cube : Cube) extends Actor
	with AggregationActorFactory
	with DimensionActorFactory {

	import context._
	implicit val timeout = Timeout(5000 milliseconds)

	override def preStart() {
		cube.aggregations.values.foreach { agg => 
			aggregationActorFor(agg)
		}

		cube.dimensions.values.foreach { dim =>
			dimensionRepoActorFor(dim)
		}
	}

	def receive = {
		case query : CellsetQuery => {	
			executeQuery(query) pipeTo sender
		}
	}

	def executeQuery(query : CellsetQuery) = {
		//TODO: if there are no filters, then we can probably get tuples without individual members
		//listed depending on the impl of the tuple store
		val dimQueries = query.dimensions.map { dim =>
			(actorFor("dimension." + dim) ? DimensionMemberQuery(dim, query.dimensionFiltersFor(dim)))
				.mapTo[DimensionMembers]
		}

		for {
			members <- Future.sequence(dimQueries).mapTo[List[DimensionMembers]]
			aggregates <- (actorFor("aggregation." + query.aggregation) ? AggregationQuery(query.aggregation, members))
				.mapTo[Iterable[Aggregate]]

		} yield Cellset(members, aggregates)
	}
	
}