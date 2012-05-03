package org.wonkavision.server.persistence

import org.wonkavision.server.messages._
import org.wonkavision.core.DimensionMember
import org.wonkavision.core.Dimension
import org.wonkavision.core.filtering.FilterOperator._

import akka.dispatch.{Promise, Future, ExecutionContext}

abstract trait DimensionRepository extends DimensionReader with DimensionWriter {
	val dimension : Dimension
}

abstract trait DimensionReader { 
	def get(key : Any) : Future[Option[DimensionMember]]
	def getMany(keys : Iterable[Any]) : Future[Iterable[DimensionMember]]
	def select(query : DimensionMemberQuery) : Future[Iterable[DimensionMember]]
	def all() : Future[Iterable[DimensionMember]]
}

abstract trait DimensionWriter {
	def put(member : DimensionMember) : Future[Any]
	def put(members : Iterable[DimensionMember]) : Future[Any]
	def delete(key : Any) : Future[Any]
	def purge() : Future[Any]
}

abstract trait KeyValueDimensionReader extends DimensionReader {
	def select(query : DimensionMemberQuery)  = {
		val (keyFilters, attrFilters) = query.filters.partition { filter =>
			filter.attributeName == "key" && (filter.operator == Eq || filter.operator == In)
		}	
		
		val vals = if (keyFilters.size > 0) {
			val keys = keyFilters.flatMap(_.values)
			getMany(keys)
		} else { 
			all
		}
		vals.map(_.filter(_.matches(attrFilters)))	
	}
}

abstract trait KeyValueDimensionWriter extends DimensionWriter {
	
}



