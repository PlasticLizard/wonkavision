package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.server.messages._
import org.wonkavision.core.Aggregation
import org.wonkavision.server.persistence._

trait AggregationActorFactory { self : Actor =>

	def aggregationActorFor(agg : Aggregation) = {
		 val props = Props(
		 	new AggregationActor {
		 		val aggregation = agg
		 		val repo = new LocalAggregationRepository(agg)(context.system.dispatcher)
		 	}
		 )
		 context.actorOf(props, "aggregation." + agg.name)
	}
}