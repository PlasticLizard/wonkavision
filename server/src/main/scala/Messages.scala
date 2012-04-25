package org.wonkavision.server.messages

import org.wonkavision.core.filtering.MemberFilterExpression
import org.wonkavision.core.MemberType._
import org.wonkavision.core.Dimension
import org.wonkavision.server.DimensionMember
import org.wonkavision.server.Aggregate

case class CellsetQuery(
	cube : String,
	aggregation : String,
	axes : List[List[String]],
	measures : List[String],
	filters : List[MemberFilterExpression]
) {
	def dimensions = axes.flatten
	def dimensionFiltersFor(dimensionName : String) = filters.filter { f =>
		f.memberType == Dimension && f.memberName == dimensionName
	}
}

case class DimensionMemberQuery(dimensionName : String, filters : Iterable[MemberFilterExpression]) {
	val hasFilter = filters.size > 0
}
case class AggregationQuery(aggregationName : String, dimensions : Iterable[DimensionMembers]) {
	val hasFilter = dimensions.exists(_.hasFilter)
	val dimensionNames = dimensions.map(_.dimension.name)
}

abstract trait QueryResult
case class ObjectNotFound(what : String, name : String) extends QueryResult {
	def message = what + " " + name + " cannot be found"
}


case class Cellset(query : CellsetQuery, members : Iterable[DimensionMembers], tuples : Iterable[Aggregate]) extends QueryResult

case class DimensionMembers(dimension : Dimension, members : Iterable[DimensionMember], hasFilter : Boolean = false) extends QueryResult


