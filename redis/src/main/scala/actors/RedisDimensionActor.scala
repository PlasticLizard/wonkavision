package org.wonkavision.redis.actors

import akka.actor.{Props, Actor, ActorRef}
import akka.routing.SmallestMailboxRouter

import org.wonkavision.core.Dimension
import org.wonkavision.server.actors.DimensionActor
import org.wonkavision.server.messages.DimensionCommand

import org.wonkavision.redis.RedisDimensionRepository

class RedisDimensionActor(val dimension : Dimension) extends Actor {
	private var workers : ActorRef = _
	override def preStart() {
		workers = context.actorOf(
			Props(new RedisDimensionWorker(dimension))
			.withRouter(SmallestMailboxRouter(10))
			.withDispatcher("redis-worker-dispatcher")
		)
	}

	def receive = {
		case cmd : DimensionCommand => workers forward cmd
	}
}

class RedisDimensionWorker(val dimension : Dimension) extends DimensionActor {
	val repo = new RedisDimensionRepository(dimension, context.system)
}