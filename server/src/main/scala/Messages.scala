package org.wonkavision.server.messages

import org.wonkavision.core.filtering.MemberFilterExpression

case class CellsetQuery(
	cube : String,
	aggregation : String,
	axes : List[List[String]],
	measures : List[String],
	filters : List[MemberFilterExpression[_]]
) {
	def dimensions = axes.flatten
	def dimensionFiltersFor(dimensionName : String) = filters
}

case class DimensionMemberQuery(dimensionName : String, filters : List[MemberFilterExpression[_]])
case class TupleQuery(aggregationName : String, dimensions : List[DimensionMembers]) extends QueryResult

abstract trait QueryResult
case class ObjectNotFound(what : String, name : String) extends QueryResult {
	def message = what + " " + name + " cannot be found"
}


case class Cellset(query : CellsetQuery, members : List[DimensionMembers], tuples : Tuples) extends QueryResult

case class DimensionMembers() extends QueryResult


case class Tuples() extends QueryResult
