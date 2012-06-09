package org.wonkavision.mongodb

import org.wonkavision.core.{Dimension, DimensionMember}
import org.wonkavision.server.persistence._

import akka.actor.ActorSystem

import org.wonkavision.server.messages._

class MongoDimensionRepository(dim : Dimension, system : ActorSystem)
	extends DimensionRepository
	with DimensionReader
	with DimensionWriter {

	implicit val dimension = dim
	
	private val mongodb = new MongoDb(system)
	def collection = mongodb.collection(dimension.fullname)

	def select(query : DimensionMemberQuery) : Iterable[DimensionMember] = List()

	def get(key : Any) : Option[DimensionMember] = {
		None
	}

	def getMany(keys : Iterable[Any]) : Iterable[DimensionMember] = {
		List()
	}

	def all() : Iterable[DimensionMember] = {
		List()
	}

	def put(member : DimensionMember) = {
		true
	}

	def put(members : Iterable[DimensionMember]) = {
		true
	}

	def delete(key : Any) = {
		true
	}

	def purge() = {
		true
	}
}