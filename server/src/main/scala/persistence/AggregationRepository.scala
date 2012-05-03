package org.wonkavision.server.persistence

import scala.collection.SortedSet

import org.wonkavision.server.messages._
import org.wonkavision.core.DimensionMember
import org.wonkavision.core.Dimension
import org.wonkavision.core.filtering.FilterOperator._
import org.wonkavision.core.Aggregation
import org.wonkavision.core.Util
import org.wonkavision.core.Aggregate

import akka.dispatch.{Promise, Future, ExecutionContext}

abstract trait AggregationRepository extends AggregationReader with AggregationWriter {
	val aggregation : Aggregation
}

abstract trait AggregationReader  {
	def get(dimensions : Iterable[String], key : Iterable[Any]) : Future[Option[Aggregate]]
	def getMany(dimensions : Iterable[String], keys : Iterable[Iterable[Any]]) : Future[Iterable[Aggregate]]
	def select(query : AggregateQuery) : Future[Iterable[Aggregate]]
	def all(dimensions : Iterable[String]) : Future[Iterable[Aggregate]]
}

abstract trait AggregationWriter {
	def put(agg : Aggregate) : Future[Any]
	def put(dimensions : Iterable[String], aggs : Iterable[Aggregate]) : Future[Any]
	def delete(dimensions : Iterable[String], key : Iterable[Any]) : Future[Any]
	def purge(dimensions : Iterable[String]) : Future[Any]
	def purgeAll() : Future[Any]
}

abstract trait KeyValueAggregationReader extends AggregationReader {

	def select(query : AggregateQuery) = {
		val dimNames = SortedSet(query.dimensionNames.toSeq:_*)
		if (query.hasFilter) {
			val keys = generateAggregationKeys(dimNames, query.dimensions)
			getMany(dimNames, keys)
		} else {
			all(dimNames)
		}
	}	

	protected def generateAggregationKeys(dims : Iterable[String], members : Iterable[DimensionMembers] ) = {
		var membersList = dims.toList.map( dim =>
				members.find(_.dimension.name == dim).get
					.members.map(_.key).toList).toList
		Util.product(membersList)
	}

	
}

abstract trait KeyValueAggregationWriter extends AggregationWriter {
	

}


