package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.server.messages._
import org.wonkavision.core.Cube

class CubeActor(val cube : Cube) extends Actor {
	import context._

	private var aggregations : Map[String, ActorRef] = Map()

	override def preStart() {
		cube.aggregations.values.foreach { agg => 
			val aa = actorOf(Props(new AggregationActor(agg)), agg.name)
			aggregations = aggregations + (agg.name -> aa)
		}
	}

	def receive = {
		case query : CellsetQuery => {	
			sender ! Cellset()	
		}
	}

	
}