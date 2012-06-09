package org.wonkavision.mongodb.actors

import akka.actor.{Props, Actor, ActorRef}
import akka.routing.SmallestMailboxRouter

import org.wonkavision.core.Aggregation
import org.wonkavision.server.actors.AggregationActor
import org.wonkavision.server.messages.AggregationCommand
import org.wonkavision.mongodb.MongoAggregationRepository

import org.wonkavision.mongodb.MongoAggregationRepository 

class MongoAggregationActor(val aggregation : Aggregation) extends Actor {
	private var workers : ActorRef = _
	override def preStart() {
		workers = context.actorOf(
			Props(new MongoAggregationWorker(aggregation))
			.withRouter(SmallestMailboxRouter(10))
			.withDispatcher("mongo-worker-dispatcher")
		)	
	}

	def receive = {
		case cmd : AggregationCommand => workers forward cmd
	}
}

class MongoAggregationWorker(val aggregation : Aggregation) extends AggregationActor {
	val repo = new MongoAggregationRepository(aggregation, context.system)
}