package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.server.messages._
import org.wonkavision.core.Dimension


class DimensionActor(val dimension : Dimension) extends Actor {
	import context._

	def receive = {
		case query : DimensionMemberQuery => {	
			sender ! DimensionMembers(List(), query)	
		}
	}

	
}