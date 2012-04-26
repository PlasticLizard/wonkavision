package org.wonkavision.server.persistence

import org.wonkavision.server.messages._
import org.wonkavision.server.DimensionMember
import org.wonkavision.core.Dimension

class LocalDimensionRepository(
	dim : Dimension,
	data : Iterable[Map[String,Any]] = List()
) extends KeyValueDimensionReader
     with KeyValueDimensionWriter {
	
	implicit val dimension = dim
	
	def get(rawKey : Any) = {
		val key = dimension.key.ensure(rawKey)
		members.get(key)
	}	

	def all() = {
		members.values
	}

	def put(rawKey : Any, member : DimensionMember) {
		val key = dimension.key.ensure(rawKey)
		members = members + (key -> member)
	}

	def delete(rawKey : Any) {
		val key = dimension.key.ensure(rawKey)
		members = members - key
	}

	def purge() {
		members = Map()
	}

	private var members : Map[Any,DimensionMember] = {
		val tuples = data.map { mdata =>
			val member = new DimensionMember(mdata)
			(member.key -> member)
		}.toSeq
		Map(tuples:_*)
	}

}