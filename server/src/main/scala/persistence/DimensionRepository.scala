package org.wonkavision.server.persistence

import org.wonkavision.server.messages._
import org.wonkavision.server.DimensionMember
import org.wonkavision.core.Dimension
import org.wonkavision.core.filtering.FilterOperator._

abstract trait DimensionRepository {
	val dimension : Dimension
}

abstract trait DimensionReader { 
	def get(key : Any) : Option[DimensionMember]
	def select(query : DimensionMemberQuery) : Iterable[DimensionMember]
	def all() : Iterable[DimensionMember]
}

abstract trait KeyValueDimensionReader extends DimensionReader {
	def select(query : DimensionMemberQuery)  = {
		val (keyFilters, attrFilters) = query.filters.partition { filter =>
			filter.attributeName == "key" && (filter.operator == Eq || filter.operator == In)
		}	

		val vals = keyFilters
					.flatMap(_.values)
					.map(get(_))
					println(vals)
					vals.flatten
		.filter(_.matches(attrFilters))
	}
}



