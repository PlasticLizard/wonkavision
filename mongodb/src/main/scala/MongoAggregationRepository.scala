
package org.wonkavision.mongodb

import org.wonkavision.server.messages._
import org.wonkavision.core.Dimension
import org.wonkavision.core.Aggregation
import org.wonkavision.core.Aggregate
import org.wonkavision.server.persistence._

import akka.actor.ActorSystem 

import com.mongodb.casbah.Imports._
import com.mongodb.casbah.commons.MongoDBObjectBuilder


class MongoAggregationRepository(val agg : Aggregation, system : ActorSystem)
	extends AggregationRepository
	with AggregationReader
    with AggregationWriter {
	
	implicit val aggregation = agg
	private val mongodb = new MongoDb(system)

	def collection = mongodb.collection(aggregation.fullname)

	def select(query : AggregateQuery) : Iterable[Aggregate] = List()

	def get(dimensionNames : Iterable[String], key : Iterable[Any]) : Option[Aggregate] = {
		None
	}	

	def all(dimensionNames : Iterable[String]) : Iterable[Aggregate] = {
		val query = createQuery(dimensionNames)
		collection.find(query).map( fromMongo(_) ).toList
	}

	def put(agg : Aggregate) = {
		val query = createQuery(agg)
		val update = toMongo(agg)

		collection.update(query, update, true, false)
		true
	}

	def put(dimensions : Iterable[String], aggs : Iterable[Aggregate]) = {
		aggs.foreach { agg : Aggregate => put(agg) }
		true
	}
	
	def purge(dimensions : Iterable[String]) = {
		val query = createQuery(dimensions)
		collection.remove(query)
		true
	}
	
	def purgeAll() = {
		collection.remove(MongoDBObject())
		true
	}
	
	def delete(dimensions : Iterable[String], key : Iterable[Any]) = {
		val query = createQuery(dimensions.toSeq, key.toSeq)
		collection.remove(query)
		true
	}

	private def createQuery(dimensions : Iterable[String]) : MongoDBObject = {
		MongoDBObject("dimensions" -> dimensions)
	}

	private def createQuery(agg : Aggregate) : MongoDBObject = {
		createQuery(agg.dimensions, agg.key)
	}

	private def createQuery(dimensions : Seq[String], key : Seq[Any]) : MongoDBObject = {
		var builder = MongoDBObject.newBuilder
		for (i <- dimensions.indices) {
				builder += (dimensions(i) -> key(i))
			}
		builder += "dimensions" -> dimensions
		builder.result
	}

	private def toMongo(agg : Aggregate) = {
		val aggObj = agg.toMap().asDBObject
		aggObj += "dimensions" -> agg.dimensions
		aggObj
	}

	private def fromMongo(data : MongoDBObject) : Aggregate = {
		null
	}

	
}