package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.server.messages._
import org.wonkavision.core.Aggregation
import org.wonkavision.server.persistence._

trait AggregationRepoActorFactory { self : Actor =>

	def aggregationRepoActorFor(agg : Aggregation) = {
		 val props = Props(
		 	new AggregationReaderActor {
		 		val aggregation = agg
		 		val reader = new LocalAggregationRepository(agg)
		 	}
		 )
		 context.actorOf(props, "aggregation." + agg.name)
	}
}