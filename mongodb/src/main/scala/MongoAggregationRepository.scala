
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

	def select(query : AggregateQuery) : Iterable[Aggregate] = {
		val dimNames = query.dimensionNames.toSeq.sorted
		if (query.hasFilter) {
				val q = createQuery(dimNames)
				for (dim <- query.dimensions if dim.hasFilter) {
					q ++= (dim.dimension.name $in dim.members.map{_.key.asInstanceOf[AnyRef]})
				}
				collection.find(q).map( fromMongo(dimNames, _)).toList			
			} else {
				all(dimNames)
			}
	}

	def get(dimensionNames : Iterable[String], key : Iterable[Any]) : Option[Aggregate] = {
		val query = createQuery(dimensionNames, key)
		collection.findOne(query).map{ fromMongo(dimensionNames, _) }
	}	

	def all(dimensionNames : Iterable[String]) : Iterable[Aggregate] = {
		val query = createQuery(dimensionNames)
		collection.find(query).map( fromMongo(dimensionNames, _) ).toList
	}

	def put(agg : Aggregate) = {
		val query = createQuery(agg)
		val update = toMongo(agg)

		collection.update(query, update, true, false)
		true
	}

	def put(dimensions : Iterable[String], aggs : Iterable[Aggregate]) = {
		collection.insert(aggs.map(toMongo(_)).toList)
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
		val query = createQuery(dimensions, key)
		collection.remove(query)
		true
	}	

	private def createQuery(dimensions : Iterable[String]) : MongoDBObject = {
		MongoDBObject("_dimensions" -> dimensions)
	}

	private def createQuery(agg : Aggregate) : MongoDBObject = {
		createQuery(agg.dimensions, agg.key)
	}

	private def createQuery(dimensions : Iterable[String], key : Iterable[Any]) : MongoDBObject = {
		val dims = dimensions.toSeq
		val keys = key.toSeq
		var builder = MongoDBObject.newBuilder
		for (i <- dims.indices) {
				builder += (dims(i) -> keys(i))
			}
		builder += "_dimensions" -> dims
		builder.result
	}

	private def toMongo(agg : Aggregate) = {
		val obj = createQuery(agg)
		agg.measures.filter(e => !e._2.isEmpty)
			.foreach{ element =>
				obj += (element._1 -> element._2.get.asInstanceOf[AnyRef])
			}
		obj
	}

	private def fromMongo(dimensions : Iterable[String], data : MongoDBObject) : Aggregate = {
		val aggdata = data - "_dimensions"
		new Aggregate(dimensions, Map(aggdata.iterator.toSeq:_*))
	}

	
}