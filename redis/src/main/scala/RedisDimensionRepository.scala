package org.wonkavision.redis

import org.wonkavision.core.{Dimension, DimensionMember}
import org.wonkavision.server.Wonkavision
import org.wonkavision.redis.serialization.MessagePack
import org.wonkavision.server.persistence._


class RedisDimensionRepository(dim : Dimension)(implicit wonkavision :Wonkavision)
	extends RedisRepository(wonkavision)
	with DimensionRepository
	with KeyValueDimensionReader
	with KeyValueDimensionWriter {

	implicit val dimension = dim

	def hashname : String = dimension.fullname

	def get(key : Any) = {
		val rKey = dimension.key.ensure(key).toString()
		exec { redis =>
			import com.redis.serialization.Parse.Implicits.parseByteArray
			val bytes = redis.hget[Array[Byte]](hashname, rKey)
			deserialize(bytes)
		}
	}

	def all() = {
		exec { redis =>
			import com.redis.serialization.Parse.Implicits.parseByteArray
			val memberData = redis.hgetall[String,Array[Byte]](hashname).getOrElse(Map())
			memberData.values.map( bytes => deserialize(Some(bytes)) )
			.flatten
		}
	}

	def put(member : DimensionMember) {
		exec { redis => 
			redis.hset(hashname, member.key.toString, serialize(member))
		}
	}

	override def put(members : Iterable[DimensionMember]) {
		val elements = members.map { member =>
			(member.key.toString, serialize(member))
		}
		exec { redis => redis.hmset(hashname, elements) }
	}

	def delete(key : Any) {
		val rKey = dimension.key.ensure(key).toString()
		exec { redis =>
			redis.hdel(hashname, rKey)
		}
	}

	def purge(){
		exec { redis => redis.del(hashname) }
	}

	def serialize(member : DimensionMember) : Array[Byte] = {
		val elements = for (i <- member.dimension.attributes.indices)
			yield (member.dimension.attributes(i).name -> member.at(i).getOrElse("").toString)
		MessagePack.writeMap(Map(elements:_*))
	}

	def deserialize(bytes : Option[Array[Byte]]) : Option[DimensionMember] = {
		bytes.map { b => 
			val data : Map[String,String] = MessagePack.readMap(b)
			new DimensionMember(data)
		}		
	}

}