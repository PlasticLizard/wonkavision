package org.wonkavision.server.persistence

import org.wonkavision.core.{Dimension, DimensionMember}
import org.wonkavision.server.Wonkavision

class RedisDimensionRepository(dim : Dimension)(implicit wonkavision :Wonkavision)
	extends RedisRepository(wonkavision)
	with DimensionRepository
	with KeyValueDimensionReader
	with KeyValueDimensionWriter {

	implicit val dimension = dim

	def get(rawKey : Any) = {
		None
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

}