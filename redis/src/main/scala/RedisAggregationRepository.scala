package org.wonkavision.redis

import org.wonkavision.server.messages._
import org.wonkavision.core.Dimension
import org.wonkavision.core.Aggregation
import org.wonkavision.core.Aggregate
import org.wonkavision.redis.serialization._
import org.wonkavision.server.persistence._

import com.redis.RedisClientPool

import akka.actor.ActorSystem 


class RedisAggregationRepository(val agg : Aggregation, system : ActorSystem)
	extends AggregationRepository
	with KeyValueAggregationReader
    with KeyValueAggregationWriter {
	
	private val redis = new Redis(system)

	implicit val aggregation = agg
	val serializer : Serializer = new MessagePackSerializer()

	def hashname(dimNames : Iterable[String]) = 
		aggregation.fullname + "~" + dimNames.mkString(":")

	def get(dimensionNames : Iterable[String], key : Iterable[Any]) = {
		val aggKey = key.mkString(":")
		
		redis.exec { redis =>
			import com.redis.serialization.Parse.Implicits.parseByteArray
			val bytes = redis.hget[Array[Byte]](hashname(dimensionNames), aggKey)
			deserialize(dimensionNames, bytes)
		}
	}	

	def all(dimensionNames : Iterable[String]) = {
		redis.exec { redis => 
			import com.redis.serialization.Parse.Implicits.parseByteArray
			val aggData = redis.hgetall[String,Array[Byte]](hashname(dimensionNames)).getOrElse(Map())
			aggData.values.map( bytes => deserialize(dimensionNames, Some(bytes)))
			.flatten
		}
	}

	def put(agg : Aggregate) = {
		val aggKey = agg.key.mkString(":")
		redis.exec { redis =>
			redis.hset(hashname(agg.dimensions), aggKey, serialize(agg))
		}
		true
	}

	override def put(dimensions : Iterable[String], aggs : Iterable[Aggregate]) = {
		val elements = aggs.map { agg =>
			(agg.key.mkString(":") -> serialize(agg))
		}
		redis.exec { redis => redis.hmset(hashname(dimensions), elements) }
		true
	}
	
	def purge(dimensions : Iterable[String]) = {
		redis.exec { redis => redis.del(hashname(dimensions)) }
		true
	}
	
	def purgeAll() = {
		val keys = aggregation.aggregations.map { dimSet =>
			hashname(dimSet)
		}.toSeq
		redis.exec { redis => redis.del(keys.head, keys.tail:_*)}
		true
	}
	
	def delete(dimensions : Iterable[String], key : Iterable[Any]) = {
		val aggKey = key.mkString(":")
		redis.exec { redis => redis.del(hashname(dimensions), aggKey) }
		true
		
	}

	def serialize(aggregate : Aggregate) : Array[Byte] = {
		serializer.write(aggregate)
	}

	def deserialize(dimensions : Iterable[String], bytes : Option[Array[Byte]]) : Option[Aggregate] = {
		serializer.readAggregate(dimensions, bytes)
	}
}