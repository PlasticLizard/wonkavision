package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.server.messages._
import org.wonkavision.core.Aggregation

class AggregationActor(val aggregation : Aggregation) extends Actor {
	import context._

	var aggregations : Map[String, ActorRef] = Map()

	override def preStart() {
		
	}

	def receive = {
		case query : AggregationQuery => {
			sender ! List()
		}
	}
}