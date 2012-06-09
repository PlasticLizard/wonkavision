
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
	
	implicit val aggregation = agg
	private val mongodb = new MongoDb(system)

	def select(query : AggregateQuery) : Iterable[Aggregate] = List()

	def collection = mongodb.collection(aggregation.fullname)

	def get(dimensionNames : Iterable[String], key : Iterable[Any]) : Option[Aggregate] = {
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
		true
	}
	
	def purgeAll() = {
		true
	}
	
	def delete(dimensions : Iterable[String], key : Iterable[Any]) = {
		true
	}

	
}