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
		 	createDimensionActor(dim)
		 )
		 .withRouter(SmallestMailboxRouter(settings.aggregationRepoWorkerCount))
		 
		 context.actorOf(props, "dimension." + dim.name)
	}

	def createDimensionActor(dimension : Dimension) = {
		val dimRepoClass = Class.forName(settings.dimensionRepoClassName)
		val argList : List[java.lang.Object] = List(dimension)
		val ctr = dimRepoClass.getConstructors.head

		ctr.newInstance(argList.toSeq:_*).asInstanceOf[Actor]
	}
}