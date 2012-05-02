package org.wonkavision.server.actors

import akka.actor.{Props, Actor, ActorRef}
import akka.dispatch.Future

import org.wonkavision.server.messages._
import org.wonkavision.core.Dimension
import org.wonkavision.core.DimensionMember
import akka.pattern.pipe
import org.wonkavision.server.persistence.DimensionRepository


abstract trait DimensionActor extends Actor {
	import context._

	val dimension : Dimension
	val repo : DimensionRepository

	def receive = {
		case query : DimensionMemberQuery => executeQuery(query) pipeTo sender
		case add : AddDimensionMember => repo.put(dimension.createMember(add.data))
		case add : AddDimensionMembers => repo.put(add.data.map(dimension.createMember(_)))
		case del : DeleteDimensionMember => repo.delete(del.key)
		case purge : PurgeDimensionMembers => repo.purge()
	}

	def executeQuery(query : DimensionMemberQuery) : Future[DimensionMembers]  = {
		repo.select(query).map{DimensionMembers(dimension,_,query.hasFilter)}
	}
}