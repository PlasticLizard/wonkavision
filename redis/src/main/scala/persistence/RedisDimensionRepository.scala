package org.wonkavision.server.persistence

import org.wonkavision.core.{Dimension, DimensionMember}
import org.wonkavision.server.Wonkavision

class RedisDimensionRepository(dim : Dimension)(implicit wonkavision :Wonkavision)
	extends RedisRepository(wonkavision)
	with DimensionRepository
	with KeyValueDimensionReader
	with KeyValueDimensionWriter {

	implicit val dimension = dim

	def hashname : String = dimension.fullname

	def get(key : Any) = {
		exec { redis =>
			fromRedis( redis.hget[String](hashname, key.toString()) )
		}
	}

	def all() = {
		List()
	}

	def put(member : DimensionMember) {
		
	}

	def delete(rawKey : Any) {

	}

	def purge(){

	}

	def toRedis(member : DimensionMember) : String = {
		val map = for (i <- member.dimension.attributes.indices)
			yield (member.dimension.attributes(i).name -> member.at(i))
		map.toString()
	}

	def fromRedis(data : Option[String]) : Option[DimensionMember] = {
		data.map{s => new DimensionMember(Map())}
	}

}