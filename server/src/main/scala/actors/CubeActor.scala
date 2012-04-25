package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.server.messages._
import org.wonkavision.core.Cube
import org.wonkavision.server.Aggregate

import akka.dispatch.{Await, Future}
import akka.pattern.{ask, pipe}
import akka.util.Timeout
import akka.util.duration._



class CubeActor(val cube : Cube) extends Actor {
	import context._
	implicit val timeout = Timeout(5000 milliseconds)

	var aggregations : Map[String, ActorRef] = Map()
	var dimensions : Map[String, ActorRef] = Map()

	override def preStart() {
		cube.aggregations.values.foreach { agg => 
			val aa = actorOf(Props(new AggregationActor(agg)), name=agg.name)
			aggregations = aggregations + (agg.name -> aa)
		}

		cube.dimensions.values.foreach { dim =>
			val da = actorOf(Props(new DimensionActor(dim)), name=dim.name)
			dimensions = dimensions + (dim.name -> da)
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
			(dimensions(dim) ? DimensionMemberQuery(dim, query.dimensionFiltersFor(dim)))
				.mapTo[DimensionMembers]
		}

		for {
			members <- Future.sequence(dimQueries).mapTo[List[DimensionMembers]]
			aggregates <- (aggregations(query.aggregation) ? AggregationQuery(query.aggregation, members))
				.mapTo[Iterable[Aggregate]]

		} yield Cellset(query, members, aggregates)
	}
	
}