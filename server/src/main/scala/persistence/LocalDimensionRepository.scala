package org.wonkavision.server.persistence

import org.wonkavision.server.messages._
import org.wonkavision.core.DimensionMember
import org.wonkavision.core.Dimension

import akka.actor.ActorSystem

class LocalDimensionRepository(dim : Dimension, val system : ActorSystem) 
	 extends DimensionRepository
	 with KeyValueDimensionReader
     with KeyValueDimensionWriter {
	
	implicit val dimension = dim
	implicit val executionContext = system.dispatcher
	private var members : Map[Any,DimensionMember] = Map()
	
	def get(rawKey : Any) = {
		val key = dimension.key.ensure(rawKey)
		members.get(key)
	}	

	def getMany(rawKeys : Iterable[Any]) = {
		rawKeys.map(get(_)).flatten
	}

	def all() = {
		members.values
	}

	def put(member : DimensionMember) = {
		members = members + (member.key -> member)
		true
	}

	def put(members : Iterable[DimensionMember]) = {
		members.map(put(_))
		true
	}

	def delete(rawKey : Any) = {
		val key = dimension.key.ensure(rawKey)
		members = members - key
		true
	}

	def purge() = {
		members = Map()
		true
	}


	def loadData(data : Iterable[Map[String,Any]]) = {
		members = {
			val tuples = data.map { mdata =>
				val member = new DimensionMember(mdata)
				(member.key -> member)
			}.toSeq
			Map(tuples:_*)
		}
	}

}