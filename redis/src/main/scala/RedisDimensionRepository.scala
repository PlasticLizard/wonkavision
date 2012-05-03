package org.wonkavision.redis

import org.wonkavision.core.{Dimension, DimensionMember}
import org.wonkavision.redis.serialization._
import org.wonkavision.server.persistence._

import akka.actor.ActorSystem

class RedisDimensionRepository(dim : Dimension, system : ActorSystem)

	extends RedisRepository(system)
	with DimensionRepository
	with KeyValueDimensionReader
	with KeyValueDimensionWriter {

	implicit val dimension = dim
	val serializer : Serializer = new MessagePackSerializer()


	def hashname : String = dimension.fullname

	def get(key : Any) = {
		val rKey = dimension.key.ensure(key).toString()
		exec { redis =>
			import com.redis.serialization.Parse.Implicits.parseByteArray
			val bytes = redis.hget[Array[Byte]](hashname, rKey)
			deserialize(bytes)
		}
	}

	def getMany(keys : Iterable[Any]) = {
		val rKeys = keys.map(_.toString).toSeq
		exec { redis =>
			import com.redis.serialization.Parse.Implicits.parseByteArray
			val memberData = redis.hmget[String,Array[Byte]](hashname, rKeys:_*).getOrElse(Map())
			memberData.values.map( bytes => deserialize(Some(bytes)) )
			.flatten
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

	def put(member : DimensionMember) = {
		exec { redis => 
			redis.hset(hashname, member.key.toString, serialize(member))
		}
	}

	def put(members : Iterable[DimensionMember]) = {
		val elements = members.map { member =>
			(member.key.toString, serialize(member))
		}
		exec { redis => redis.hmset(hashname, elements) }
	}

	def delete(key : Any) = {
		val rKey = dimension.key.ensure(key).toString()
		exec { redis =>
			redis.hdel(hashname, rKey)
		}
	}

	def purge() = {
		exec { redis => redis.del(hashname) }
	}

	def serialize(member : DimensionMember) : Array[Byte] = {
		serializer.write(member)
	}

	def deserialize(bytes : Option[Array[Byte]]) : Option[DimensionMember] = {
		serializer.readDimensionMember(bytes)
	}

}