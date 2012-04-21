package org.wonkavision.server.persistence

import org.wonkavision.server.messages._
import org.wonkavision.server.DimensionMember
import org.wonkavision.core.Dimension

class StaticDimensionRepository(
	dim : Dimension,
	data : Iterable[Map[String,Any]]
) extends DimensionRepository with KeyValueDimensionReader {
	
	implicit val dimension = dim
	
	def get(rawKey : Any) = {
		val key = dimension.key.ensure(rawKey)
		members.get(key)
	}	

	def all() = {
		members.values
	}

	private val members : Map[Any,DimensionMember] = {
		val tuples = data.map { mdata =>
			val member = new DimensionMember(mdata)
			(member.key -> member)
		}.toSeq
		Map(tuples:_*)
	}

}