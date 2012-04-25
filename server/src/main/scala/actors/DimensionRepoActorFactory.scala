package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.server.messages._
import org.wonkavision.core.Dimension
import org.wonkavision.server.persistence._

trait DimensionRepoActorFactory { self : Actor =>

	def dimensionRepoActorFor(dim : Dimension) = {
		 val props = Props(
		 	new DimensionReaderActor {
		 		val dimension = dim
		 		val reader = new LocalDimensionRepository(dim)
		 	}
		 )
		 context.actorOf(props, "dimension." + dim.name)
	}
}