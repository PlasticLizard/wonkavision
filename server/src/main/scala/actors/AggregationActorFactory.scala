package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}
import akka.routing.SmallestMailboxRouter

import org.wonkavision.server.messages._
import org.wonkavision.core.Aggregation
import org.wonkavision.server.persistence._

trait AggregationActorFactory { self : CubeActor =>

	def aggregationActorFor(agg : Aggregation) = {
		 val props = Props(
		 	new AggregationActor {
		 		val aggregation = agg
		 		val repo = createRepository(agg)
		 	}
		 )
		 .withRouter(SmallestMailboxRouter(settings.aggregationRepoWorkerCount))
		 .withDispatcher("repo-dispatcher")
		 
		 context.actorOf(props, "aggregation." + agg.name)
	}

	def createRepository(aggregation : Aggregation) = {
		val aggRepoClass = Class.forName(settings.aggregationRepoClassName)
		val argList : List[java.lang.Object] = List(aggregation, context.system)
		val ctr = aggRepoClass.getConstructors.head

		ctr.newInstance(argList.toSeq:_*).asInstanceOf[AggregationRepository]
	}
}