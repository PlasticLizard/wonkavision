package org.wonkavision.server.persistence

import org.wonkavision.core.Aggregate
import org.wonkavision.server.messages._
import org.wonkavision.core.Dimension
import org.wonkavision.core.Aggregation
import org.wonkavision.server.Wonkavision

import akka.dispatch.{Promise, Future, ExecutionContext}

class LocalAggregationRepository(
	val agg : Aggregation,
	data : Map[Iterable[String],Iterable[Map[String,Any]]] = Map()
)(implicit val executionContext : ExecutionContext)
	 extends AggregationRepository
	 with KeyValueAggregationReader
     with KeyValueAggregationWriter {
	
	implicit val aggregation = agg

	def get(dimensionNames : Iterable[String], key : Iterable[Any]) = {
		val aggKey = key.mkString(":")
		val dimSet = aggregationSet(dimensionNames)
		Promise.successful( 
			if (dimSet.isEmpty) None else dimSet.get.get(aggKey)
		)
	}	

	def getMany(dimensionNames : Iterable[String], keys : Iterable[Iterable[Any]]) = {
		val futures = keys.map{ key => get(dimensionNames, key).map(_.getOrElse(null))}
		Future.sequence(futures).map{_.filter{agg => agg != null}}
	}


	def all(dimensionNames : Iterable[String]) = {
		Promise.successful(
			aggregationSet(dimensionNames).map(_.values)
				.toList.flatten
		)
	}

	def put(agg : Aggregate) {
		val aggKey = agg.key.mkString(":")
		val dimKey = agg.dimensions.mkString(":")
		val dimSet = aggregationSet(agg.dimensions, true).get
		val newSet = dimSet + (aggKey -> agg)
		aggregationSets = aggregationSets + (dimKey -> newSet)
	}
	
	def purge(dimensions : Iterable[String]) {
		val dimKey = dimensions.mkString(":")
		aggregationSets = aggregationSets - dimKey
	}
	
	def purgeAll() {
		aggregationSets = Map()
	}
	
	def delete(dimensions : Iterable[String], key : Iterable[Any]) {
		val aggKey = key.mkString(":")
		val dimKey = dimensions.mkString(":")
		aggregationSet(dimensions).foreach { dimSet =>
			val newSet = dimSet - aggKey
			aggregationSets = aggregationSets + (dimKey -> newSet)
		}
		
	}

	protected def aggregationSet(dimensionNames : Iterable[String], createIfMissing : Boolean = false) = {
		val dimKey = dimensionNames.mkString(":")
		if (createIfMissing) {
			aggregationSets.get(dimKey).orElse {
				val newSet = Map[String,Aggregate]()
				aggregationSets = aggregationSets + (dimKey -> newSet)
				Some(newSet)
			} 
		} else {
			aggregationSets.get(dimKey)
		}
		
	}

	private var aggregationSets : Map[String,Map[String,Aggregate]] = data.map { dimSet =>
		val (dimNames, aggData) = dimSet
		val tuples = aggData.map { aggMap =>
			val agg = new Aggregate(dimNames, aggMap)
			(agg.key.mkString(":") -> agg)
		}.toSeq
		(dimNames.mkString(":"), Map(tuples:_*))
	}
	

}