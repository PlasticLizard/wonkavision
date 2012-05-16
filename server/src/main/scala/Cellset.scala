package org.wonkavision.server.messages

import org.wonkavision.core.Cube
import org.wonkavision.core.filtering.MemberFilterExpression
import org.wonkavision.core.MemberType
import org.wonkavision.core.MemberType._
import org.wonkavision.core.Dimension
import org.wonkavision.core.DimensionMember
import org.wonkavision.core.Aggregate


class Cellset(
	val query : CellsetQuery,
	val members : Iterable[DimensionMembers],
	val aggregates : Iterable[Aggregate]
	) extends QueryResult {


	def toMap() : Map[String,Any] = {
		val sortedDims = query.dimensions.sorted
		val keyOrder = query.dimensions.map(sortedDims.indexOf(_))
		Map(
			"cube" -> query.cubeName,
			"aggregation" -> query.aggregationName,
			"axes" -> axesMap(),
			"cells" -> aggregates.map(_.toMap(keyOrder, query.measures)),
			"measure_names" -> query.measures,
			"filters" -> query.filters.map(_.toString())
		)
	}

	def axesMap() = {
		query.axes.map { dims =>
			Map(
				"dimensions" -> dims.map { dim =>
					Map(
						"name" -> dim,
						"members" -> membersMap(dim)
					)
				}
			)
		}
	}

	def membersMap(dim : String) = {
		members.find(m=>m.dimension.name == dim)
			.get
			.members.map(_.toMap)
	}
}

