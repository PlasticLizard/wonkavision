package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.core.Cube
import org.wonkavision.server.messages._

class WonkavisionActor(cubes : Iterable[Cube]) extends Actor {
	import context._

	val initialCubeList = cubes

	override def preStart() {
		initialCubeList.foreach { register( _ ) }
	}

	def receive = {
		case cc : CubeCommand => actorFor(cc.cubeName) forward cc
		case reg : RegisterCube => register( reg.cube )
	}

	def register(cube : Cube) = {
		actorOf(Props(new CubeActor(cube)), name=cube.name)
	}
}