package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}
import akka.routing.SmallestMailboxRouter

import org.wonkavision.server.messages._
import org.wonkavision.core.Dimension
import org.wonkavision.server.persistence._

import scala.collection.JavaConversions._

trait DimensionActorFactory { self : CubeActor =>

	def dimensionRepoActorFor(dim : Dimension) = {
		 val props = Props(
		 	new DimensionActor {
		 		val dimension = dim
		 		val repo = createRepository(dim)
		 	}
		 ).withRouter(SmallestMailboxRouter(settings.aggregationRepoWorkerCount))
		  .withDispatcher("repo-dispatcher")
		 context.actorOf(props, "dimension." + dim.name)
	}

	def createRepository(dimension : Dimension) = {
		val dimRepoClass = Class.forName(settings.dimensionRepoClassName)
		val argList : List[java.lang.Object] = List(dimension, context.system)
		val ctr = dimRepoClass.getConstructors.head

		ctr.newInstance(argList.toSeq:_*).asInstanceOf[DimensionRepository]
	}
}