package org.wonkavision.server.persistence

import org.wonkavision.server.messages._
import org.wonkavision.server.DimensionMember
import org.wonkavision.core.Dimension
import org.wonkavision.core.filtering.FilterOperator._
import org.wonkavision.core.Aggregation

abstract trait AggregationRepository {
	val aggregation : Aggregation
}

abstract trait AggregationReader {
	def get(dimensions : Iterable[String], key : Iterable[Any]) : Option[Aggregate]
	def select(query : AggregationQuery) : Iterable[Aggregate]
	def all(dimensions : Iterable[String]) : Iterable[Aggregate]
}

abstract trait KeyValueAggregationReader extends AggregationReader {
	def select(query : AggregationQuery) = {
		List()
	}
}


