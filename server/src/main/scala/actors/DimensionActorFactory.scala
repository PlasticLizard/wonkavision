package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.server.messages._
import org.wonkavision.core.Dimension
import org.wonkavision.server.persistence._

trait DimensionActorFactory { self : Actor =>

	def dimensionRepoActorFor(dim : Dimension) = {
		 val props = Props(
		 	new DimensionActor {
		 		val dimension = dim
		 		val repo = new LocalDimensionRepository(dim)(context.system.dispatcher)
		 	}
		 )
		 context.actorOf(props, "dimension." + dim.name)
	}
}