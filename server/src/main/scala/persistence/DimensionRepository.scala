package org.wonkavision.server.persistence

import org.wonkavision.server.messages._
import org.wonkavision.server.DimensionMember
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
	def put(key : Any, member : DimensionMember)
	def put(members : Map[Any,DimensionMember])
	def load(members : Map[Any, DimensionMember])
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
	def put(members : Map[Any,DimensionMember]) {
		members.foreach { kv =>
			val (key, member) = kv
			put(key, member)
		}
	}

	def load(members : Map[Any, DimensionMember]) {
		purge()
		put(members)
	}
}



