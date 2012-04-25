package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.core.Cube
import org.wonkavision.server.messages._

class WonkavisionActor extends Actor {
	import context._

	override def preStart() {
		Cube.cubes.values.foreach { cube =>
			actorOf(Props(new CubeActor(cube)), name=cube.name)
		}
	}

	def receive = {
		case query : CellsetQuery => {
			actorFor(query.cube) forward query		
		}
	}


}