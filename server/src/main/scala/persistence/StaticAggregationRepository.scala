package org.wonkavision.server.persistence

import org.wonkavision.server.Aggregate
import org.wonkavision.server.messages._
import org.wonkavision.core.Dimension
import org.wonkavision.core.Aggregation

class StaticAggregationRepository(
	val agg : Aggregation,
	data : Map[Iterable[String],Iterable[Map[String,Any]]]
) extends KeyValueAggregationReader {
	
	implicit val aggregation = agg

	def get(dimensionNames : Iterable[String], key : Iterable[Any]) = {
		val aggKey = key.mkString(":")
		val dimSet = aggregationSet(dimensionNames)
		if (dimSet.isEmpty) None else dimSet.get.get(aggKey)
	}	

	def all(dimensionNames : Iterable[String]) = {
		aggregationSet(dimensionNames).map(_.values)
			.toList.flatten
	}

	protected def aggregationSet(dimensionNames : Iterable[String]) = {
		aggregationSets.get(dimensionNames.mkString(":"))
	}

	private val aggregationSets : Map[String,Map[String,Aggregate]] = data.map { dimSet =>
		val (dimNames, aggData) = dimSet
		val tuples = aggData.map { aggMap =>
			val agg = new Aggregate(dimNames, aggMap)
			(agg.key.mkString(":") -> agg)
		}.toSeq
		(dimNames.mkString(":"), Map(tuples:_*))
	}
	

}