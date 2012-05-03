package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}
import akka.routing.SmallestMailboxRouter

import org.wonkavision.server.messages._
import org.wonkavision.core.Aggregation
import org.wonkavision.server.persistence._

trait AggregationActorFactory { self : CubeActor =>

	def aggregationActorFor(agg : Aggregation) = {
		 val props = Props(
		 	createAggregationActor(agg)
		 )
		 .withRouter(SmallestMailboxRouter(settings.aggregationRepoWorkerCount))
		 
		 context.actorOf(props, "aggregation." + agg.name)
	}

	private[this] def createAggregationActor(aggregation : Aggregation) = {
		val aggRepoClass = Class.forName(settings.aggregationRepoClassName)
		val argList : List[java.lang.Object] = List(aggregation)
		val ctr = aggRepoClass.getConstructors.head

		ctr.newInstance(argList.toSeq:_*).asInstanceOf[Actor]
	}
}