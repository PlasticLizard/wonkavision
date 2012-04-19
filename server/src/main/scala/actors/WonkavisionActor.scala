package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.core.Cube
import org.wonkavision.server.messages._

class WonkavisionActor extends Actor {
	import context._

	private var cubes : Map[String, ActorRef] = Map()

	override def preStart() {
		Cube.cubes.values.foreach { cube =>
			val ca = actorOf(Props(new CubeActor(cube)), cube.name)
			cubes = cubes + (cube.name -> ca)
		}
	}

	def receive = {
		case query : CellsetQuery => {
			cubes(query.cube) forward query		
		}
	}
}