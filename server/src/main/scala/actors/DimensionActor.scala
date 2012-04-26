package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}

import org.wonkavision.server.messages._
import org.wonkavision.core.Dimension
import org.wonkavision.server.DimensionMember
import org.wonkavision.server.persistence.DimensionRepository


abstract trait DimensionActor extends Actor {
	import context._

	val dimension : Dimension
	val repo : DimensionRepository

	def receive = {
		case query : DimensionMemberQuery => sender ! executeQuery(query)
		case add : AddDimensionMember => repo.put(add.key, add.member)
		case add : AddDimensionMembers => repo.put(add.members)
		case del : DeleteDimensionMember => repo.delete(del.key)
		case purge : Purge => repo.purge()
	}

	def executeQuery(query : DimensionMemberQuery) : DimensionMembers  = {
		DimensionMembers(dimension, repo.select(query), query.hasFilter)
	}
}