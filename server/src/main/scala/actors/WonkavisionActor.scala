package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.core.Cube
import org.wonkavision.server.messages._

class WonkavisionActor extends Actor {
	import context._

	override def preStart() {
		Cube.cubes.values.foreach { register( _ ) }
	}

	def receive = {
		case query : CellsetQuery => actorFor(query.cube) forward query		
		case reg : RegisterCube => register( reg.cube )
	}

	def register(cube : Cube) = actorOf(Props(new CubeActor(cube)), name=cube.name)
}