package org.wonkavision.server.messages

import org.wonkavision.core.Cube
import org.wonkavision.core.filtering.MemberFilterExpression
import org.wonkavision.core.MemberType
import org.wonkavision.core.MemberType._
import org.wonkavision.core.Dimension
import org.wonkavision.core.DimensionMember
import org.wonkavision.core.Aggregate

abstract trait WonkavisionMessage
abstract trait Command extends WonkavisionMessage
abstract trait Query extends Command
abstract trait QueryResult extends WonkavisionMessage 

case class ObjectNotFound(what : String, name : String) extends QueryResult {
	def message = what + " " + name + " cannot be found"
}

case class RegisterCube(cube : Cube) extends Command

abstract trait CubeCommand extends Command { val cubeName : String }

abstract trait CubeQuery extends CubeCommand
case class CellsetQuery(
	cubeName : String,
	aggregationName : String,
	axes : List[List[String]],
	measures : List[String],
	filters : List[MemberFilterExpression]
) extends CubeQuery {
	def dimensions = axes.flatten
	def dimensionFiltersFor(dimensionName : String) = filters.filter { f =>
		f.memberType == MemberType.Dimension && f.memberName == dimensionName
	}
}

abstract trait DimensionCommand extends CubeCommand { val dimensionName : String }
case class AddDimensionMember(cubeName : String, dimensionName : String, data : Map[String,Any]) extends DimensionCommand
case class AddDimensionMembers(cubeName : String, dimensionName : String, data : Iterable[Map[String,Any]]) extends DimensionCommand
case class DeleteDimensionMember(cubeName : String, dimensionName : String, key : Any) extends DimensionCommand
case class PurgeDimensionMembers(cubeName : String, dimensionName : String) extends DimensionCommand

abstract trait DimensionQuery extends DimensionCommand with Query
case class DimensionMemberQuery(cubeName : String, dimensionName : String, filters : Iterable[MemberFilterExpression]) extends DimensionQuery {
	val hasFilter = filters.size > 0
}
case class DimensionMembers(dimension : Dimension, members : Iterable[DimensionMember], hasFilter : Boolean) extends QueryResult

abstract trait AggregationCommand extends CubeCommand { val aggregationName : String }
case class AddAggregate(cubeName : String, aggregationName : String, dimensions : Iterable[String], data : Map[String,Any]) extends AggregationCommand
case class AddAggregates(cubeName : String, aggregationName : String, dimensions : Iterable[String], data : Iterable[Map[String,Any]]) extends AggregationCommand
case class DeleteAggregate(cubeName : String, aggregationName : String, dimensions : Iterable[String], key : Iterable[Any]) extends AggregationCommand
case class PurgeDimensionSet(cubeName : String, aggregationName : String, dimensions : Iterable[String]) extends AggregationCommand
case class PurgeAggregation(cubeName : String, aggregationName : String) extends AggregationCommand

abstract trait AggregationQuery extends AggregationCommand with Query
case class AggregateQuery(cubeName : String, aggregationName : String, dimensions : Iterable[DimensionMembers]) extends AggregationQuery {
	val hasFilter = dimensions.exists(_.hasFilter)
	val dimensionNames = dimensions.map(_.dimension.name)
}