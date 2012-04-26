package org.wonkavision.server.persistence

import scala.collection.SortedSet

import org.wonkavision.server.messages._
import org.wonkavision.server.DimensionMember
import org.wonkavision.core.Dimension
import org.wonkavision.core.filtering.FilterOperator._
import org.wonkavision.core.Aggregation
import org.wonkavision.core.Util
import org.wonkavision.server.Aggregate

abstract trait AggregationRepository {
	val aggregation : Aggregation
}

abstract trait AggregationReader  {
	def get(dimensions : Iterable[String], key : Iterable[Any]) : Option[Aggregate]
	def select(query : AggregationQuery) : Iterable[Aggregate]
	def all(dimensions : Iterable[String]) : Iterable[Aggregate]
}

abstract trait KeyValueAggregationReader extends AggregationReader {
	def select(query : AggregationQuery) = {
		val dimNames = SortedSet(query.dimensionNames.toSeq:_*)
		if (query.hasFilter) {
			val keys = generateAggregationKeys(dimNames, query.dimensions)
			keys.map(get(dimNames, _)).flatten
		} else {
			all(dimNames)
		}
	}

	protected def generateAggregationKeys(dims : Iterable[String], members : Iterable[DimensionMembers] ) = {
		val membersList = dims.map( dim =>
				members.find(_.dimension.name == dim).get
					.members.map(_.key).toList).toList
		Util.product(membersList)
	}

	
}

abstract trait AggregationWriter {
	def put(dimensions : Iterable[String], key : Iterable[Any], agg : Aggregate)
	def put(dimensions : Iterable[String], aggs : Map[_ <: Iterable[Any], Aggregate])
	def load(dimensions : Iterable[String], aggs : Map[_ <: Iterable[Any], Aggregate])
	def delete(dimensions : Iterable[String], key : Iterable[Any])
	def purge(dimensions : Iterable[String])
	def purgeAll()
}

abstract trait KeyValueAggregationWriter extends AggregationWriter {
	def put(dimensions : Iterable[String], aggs : Map[_ <: Iterable[Any], Aggregate]) {
		aggs.foreach { kv =>
			val (key, agg) = kv
			put(dimensions, key, agg)
		}
	}

	def load(dimensions : Iterable[String], aggs : Map[_ <: Iterable[Any], Aggregate]) {
		purge(dimensions)
		put(dimensions, aggs)
	}

}


