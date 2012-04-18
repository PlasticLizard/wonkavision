package org.wonkavision.server.actors

import akka.actor.{Props, Actor}

import org.wonkavision.server.messages._
import org.wonkavision.core.Cube

class CubeActor(val cube : Cube) extends Actor {
	import context._

	override def preStart() {
	}

	def receive = {
		case query : Query => {
			println(cube.name + " received a query")
			sender ! Cellset()
		}
	}
}