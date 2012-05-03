package org.wonkavision.redis

import org.wonkavision.server.messages._
import org.wonkavision.core.Dimension
import org.wonkavision.core.Aggregation
import org.wonkavision.core.Aggregate
import org.wonkavision.server.Wonkavision
import org.wonkavision.redis.serialization._
import org.wonkavision.server.persistence._


class RedisAggregationRepository(
	val agg : Aggregation,
	val serializer : Serializer = new MessagePackSerializer())
	(implicit wonkavision : Wonkavision)
	
	extends RedisRepository(wonkavision)
	with AggregationRepository
	with KeyValueAggregationReader
    with KeyValueAggregationWriter {
	
	implicit val aggregation = agg

	def hashname(dimNames : Iterable[String]) = 
		aggregation.fullname + "~" + dimNames.mkString(":")

	def get(dimensionNames : Iterable[String], key : Iterable[Any]) = {
		val aggKey = key.mkString(":")
		
		exec { redis =>
			import com.redis.serialization.Parse.Implicits.parseByteArray
			val bytes = redis.hget[Array[Byte]](hashname(dimensionNames), aggKey)
			deserialize(dimensionNames, bytes)
		}
	}	

	def getMany(dimensionNames : Iterable[String], keys : Iterable[Iterable[Any]]) = {
		exec { redis =>
			import com.redis.serialization.Parse.Implicits.parseByteArray
			val rKeys = keys.map(_.mkString(":"))
			val aggData = redis.hmget[String,Array[Byte]](
				hashname(dimensionNames),
				rKeys.toSeq:_*
			).getOrElse(Map())
			aggData.values.map( bytes => deserialize(dimensionNames, Some(bytes))).flatten
		}
	}

	def all(dimensionNames : Iterable[String]) = {
		exec { redis => 
			import com.redis.serialization.Parse.Implicits.parseByteArray
			val aggData = redis.hgetall[String,Array[Byte]](hashname(dimensionNames)).getOrElse(Map())
			aggData.values.map( bytes => deserialize(dimensionNames, Some(bytes))).flatten
		}
	}

	def put(agg : Aggregate) = {
		val aggKey = agg.key.mkString(":")
		exec { redis =>
			redis.hset(hashname(agg.dimensions), aggKey, serialize(agg))
		}
	}

	override def put(dimensions : Iterable[String], aggs : Iterable[Aggregate]) = {
		val elements = aggs.map { agg =>
			(agg.key.mkString(":") -> serialize(agg))
		}
		exec { redis => redis.hmset(hashname(dimensions), elements) }
	}
	
	def purge(dimensions : Iterable[String]) = {
		exec { redis => redis.del(hashname(dimensions)) }
	}
	
	def purgeAll() = {
		val keys = aggregation.aggregations.map { dimSet =>
			hashname(dimSet)
		}.toSeq
		exec { redis => redis.del(keys.head, keys.tail:_*)}
	}
	
	def delete(dimensions : Iterable[String], key : Iterable[Any]) = {
		val aggKey = key.mkString(":")
		exec { redis => redis.del(hashname(dimensions), aggKey) }
		
	}

	def serialize(aggregate : Aggregate) : Array[Byte] = {
		serializer.write(aggregate)
	}

	def deserialize(dimensions : Iterable[String], bytes : Option[Array[Byte]]) : Option[Aggregate] = {
		serializer.readAggregate(dimensions, bytes)
	}
}