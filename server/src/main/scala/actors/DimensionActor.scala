package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.server.messages._
import org.wonkavision.core.Dimension
import org.wonkavision.core.DimensionMember
import org.wonkavision.server.persistence.{DimensionRepository, LocalDimensionRepository}


abstract trait DimensionActor extends Actor {
	import context._

	val dimension : Dimension
	val repo : DimensionRepository

	def receive = {
		case query : DimensionMemberQuery => sender ! executeQuery(query)
		case add : AddDimensionMember => repo.put(dimension.createMember(add.data))
		case add : AddDimensionMembers => repo.put(add.data.map(dimension.createMember(_)))
		case del : DeleteDimensionMember => repo.delete(del.key)
		case purge : PurgeDimensionMembers => repo.purge()
	}

	def executeQuery(query : DimensionMemberQuery) : DimensionMembers  = {
		DimensionMembers(dimension, repo.select(query), query.hasFilter)
	}
}

class LocalDimensionActor(val dimension : Dimension) extends DimensionActor {
	val repo = new LocalDimensionRepository(dimension, context.system)	
}