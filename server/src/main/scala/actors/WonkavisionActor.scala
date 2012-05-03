package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}
import scala.collection.mutable.Set

import org.wonkavision.core.Cube
import org.wonkavision.server.messages._
import org.wonkavision.server.CubeSettings

class WonkavisionActor() extends Actor {
	import context._

	val cubes : Set[String] = Set()

	override def preStart() {
		Cube.cubes.values.foreach { register( _ ) }
	}

	def receive = {
		case cc : CubeCommand => actorFor(cc.cubeName) forward cc
		case reg : RegisterCube => register( reg.cube )
	}

	def register(cube : Cube) = {
		if (!cubes.contains(cube.name)){
			cubes += cube.name
			actorOf(Props(new CubeActor(cube)), name=cube.name)
		}
	}
}