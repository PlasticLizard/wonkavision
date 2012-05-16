package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.server.messages._
import org.wonkavision.core.Cube
import org.wonkavision.core.Aggregate
import org.wonkavision.server.CubeSettings

import akka.dispatch.{Await, Future}
import akka.pattern.{ask, pipe}
import akka.util.Timeout
import akka.util.duration._





class CubeActor(val cube : Cube) extends Actor
	with AggregationActorFactory
	with DimensionActorFactory {

	import context._
	implicit val timeout = Timeout(30000 milliseconds)
	val settings = CubeSettings.forCube(cube.name)
	var enabled = settings.enabled
	override def preStart() {
		
		cube.aggregations.values.foreach { agg => 
			aggregationActorFor(agg)
		}

		cube.dimensions.values.foreach { dim =>
			dimensionRepoActorFor(dim)
		}
	}

	def receive = {
		case _ if !enabled =>
			sender ! ObjectNotFound("Cube", cube.name)
		case query : CellsetQuery => 	
			executeQuery(query) pipeTo sender
		case query : AggregationQuery => 
			aggActorFor(query.aggregationName) ? query
		case cmd : AggregationCommand =>
			aggActorFor(cmd.aggregationName) ! cmd
		case query : DimensionQuery =>
			dimActorFor(query.dimensionName) ? query
		case cmd : DimensionCommand =>
			dimActorFor(cmd.dimensionName) ! cmd
	}

	def executeQuery(query : CellsetQuery) = {
		//TODO: if there are no filters, then we can probably get tuples without individual members
		//listed depending on the impl of the tuple store
		val dimQueries = query.dimensions.map { dim =>
			(dimActorFor(dim) ? DimensionMemberQuery(query.cubeName, dim, query.dimensionFiltersFor(dim)))
				.mapTo[DimensionMembers]
		}

		for {
			members <- Future.sequence(dimQueries).mapTo[List[DimensionMembers]]
			aggregates <- (aggActorFor(query.aggregationName) ? AggregateQuery(query.cubeName, query.aggregationName, members))
				.mapTo[Iterable[Aggregate]]

		} yield new Cellset(query, members, aggregates)
	}

	private def aggActorFor(agg : String) = actorFor("aggregation." + agg)
	private def dimActorFor(dim : String) = actorFor("dimension." + dim)
	
}