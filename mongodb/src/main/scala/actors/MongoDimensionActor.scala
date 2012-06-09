package org.wonkavision.mongodb.actors

import akka.actor.{Props, Actor, ActorRef}
import akka.routing.SmallestMailboxRouter

import org.wonkavision.core.Dimension
import org.wonkavision.server.actors.DimensionActor
import org.wonkavision.server.messages.DimensionCommand

import org.wonkavision.mongodb.MongoDimensionRepository

class MongoDimensionActor(val dimension : Dimension) extends Actor {
	private var workers : ActorRef = _
	override def preStart() {
		workers = context.actorOf(
			Props(new MongoDimensionWorker(dimension))
			.withRouter(SmallestMailboxRouter(10))
			.withDispatcher("mongo-worker-dispatcher")
		)
	}

	def receive = {
		case cmd : DimensionCommand => workers forward cmd
	}
}

class MongoDimensionWorker(val dimension : Dimension) extends DimensionActor {
	val repo = new MongoDimensionRepository(dimension, context.system)
}