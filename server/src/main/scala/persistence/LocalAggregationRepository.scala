package org.wonkavision.server.persistence

import org.wonkavision.core.Aggregate
import org.wonkavision.server.messages._
import org.wonkavision.core.Dimension
import org.wonkavision.core.Aggregation
import org.wonkavision.server.Wonkavision

import akka.actor.ActorSystem

class LocalAggregationRepository(agg : Aggregation, val system : ActorSystem)
	 extends AggregationRepository
	 with KeyValueAggregationReader
     with KeyValueAggregationWriter {
	
	private var aggregationSets : Map[String,Map[String,Aggregate]] = Map()
	implicit val aggregation = agg
	implicit val executionContext = system.dispatcher

	def get(dimensionNames : Iterable[String], key : Iterable[Any]) = {
		val aggKey = key.mkString(":")
		val dimSet = aggregationSet(dimensionNames)
		if (dimSet.isEmpty) None else dimSet.get.get(aggKey)
	}	

	def all(dimensionNames : Iterable[String]) = {
		aggregationSet(dimensionNames).map(_.values)
			.toList.flatten
	}

	def put(agg : Aggregate) {
		val aggKey = agg.key.mkString(":")
		val dimKey = agg.dimensions.mkString(":")
		val dimSet = aggregationSet(agg.dimensions, true).get
		val newSet = dimSet + (aggKey -> agg)
		aggregationSets = aggregationSets + (dimKey -> newSet)
	}

	def put(dimensions : Iterable[String], aggs : Iterable[Aggregate]) = {
		aggs.foreach(put(_))
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

	def loadData(data : Map[Iterable[String],Iterable[Map[String,Any]]]) {
		aggregationSets = data.map { dimSet =>
			val (dimNames, aggData) = dimSet
			val tuples = aggData.map { aggMap =>
				val agg = new Aggregate(dimNames, aggMap)
				(agg.key.mkString(":") -> agg)
			}.toSeq
			(dimNames.mkString(":"), Map(tuples:_*))
		}
	}

	private def aggregationSet(dimensionNames : Iterable[String], createIfMissing : Boolean = false) = {
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

	

}