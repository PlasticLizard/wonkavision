package org.wonkavision.redis.actors

import akka.actor.{Props, Actor, ActorRef}
import akka.routing.SmallestMailboxRouter


import org.wonkavision.core.Aggregation
import org.wonkavision.server.actors.AggregationActor
import org.wonkavision.server.messages.AggregationCommand
import org.wonkavision.redis.RedisAggregationRepository

class RedisAggregationActor(val aggregation : Aggregation) extends Actor {
	
	private var workers : ActorRef = _
	override def preStart() {
		workers = context.actorOf(
			Props(new RedisAggregationWorker(aggregation))
			.withRouter(SmallestMailboxRouter(10))
			.withDispatcher("redis-worker-dispatcher")
		)	
	}

	def receive = {
		case cmd : AggregationCommand => workers forward cmd
	}
}

class RedisAggregationWorker(val aggregation : Aggregation) extends AggregationActor {
	val repo = new RedisAggregationRepository(aggregation, context.system)
}