package org.wonkavision.mongodb

import org.wonkavision.server.messages._
import org.wonkavision.core.Dimension
import org.wonkavision.core.Aggregation
import org.wonkavision.core.Aggregate
import org.wonkavision.server.persistence._

import akka.actor.ActorSystem 


class MongoAggregationRepository(val agg : Aggregation, system : ActorSystem)
	extends AggregationRepository
	with AggregationReader
    with AggregationWriter {
	
	private val mongodb = new MongoDb(system)

	implicit val aggregation = agg

	def collection = mongodb.collection(aggregation.fullName)

	def get(dimensionNames : Iterable[String], key : Iterable[Any]) : Option[Aggregate] = {
		val aggKey = key.mkString(":")
		
		None
	}	

	def all(dimensionNames : Iterable[String]) : Iterable[Aggregate] = {
		List()
	}

	def put(agg : Aggregate) = {
		val aggKey = agg.key.mkString(":")
		true
	}

	override def put(dimensions : Iterable[String], aggs : Iterable[Aggregate]) = {
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