package org.wonkavision.server.persistence

import org.wonkavision.server.messages._
import org.wonkavision.core.DimensionMember
import org.wonkavision.core.Dimension
import org.wonkavision.core.filtering.FilterOperator._

abstract trait DimensionRepository extends DimensionReader with DimensionWriter {
	val dimension : Dimension
}

abstract trait DimensionReader { 
	def get(key : Any) : Option[DimensionMember]
	def select(query : DimensionMemberQuery) : Iterable[DimensionMember]
	def all() : Iterable[DimensionMember]
}

abstract trait DimensionWriter {
	def put(member : DimensionMember)
	def put(members : Iterable[DimensionMember])
	def delete(key : Any)
	def purge()
}

abstract trait KeyValueDimensionReader extends DimensionReader {
	def select(query : DimensionMemberQuery)  = {
		val (keyFilters, attrFilters) = query.filters.partition { filter =>
			filter.attributeName == "key" && (filter.operator == Eq || filter.operator == In)
		}	
		
		val vals = if (keyFilters.size > 0) {
			keyFilters
				.flatMap(_.values)
				.map(get(_))
				.flatten
		} else { 
			all
		}
		vals.filter(_.matches(attrFilters))	
	}
}

abstract trait KeyValueDimensionWriter extends DimensionWriter {
	def put(members : Iterable[DimensionMember]) {
		members.foreach(put(_))
	}
}



