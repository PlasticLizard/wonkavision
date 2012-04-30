package org.wonkavision.core

import scala.collection.immutable.SortedSet


class Aggregate(dims : Iterable[String], data : Map[String,Any])(implicit val aggregation : Aggregation) {

	val dimensions = dims.toSeq.sortBy(s=>s)
	val key : Iterable[Any] = dimensions.map( d => getKeyComponent(d, data)) 
	val measures : Map[String, Option[Double]] = measureNames.map(m => (m -> getMeasure(m,data))).toMap

	def apply(measureName : String) = measures(measureName)
	def measureNames = aggregation.measures
	def measureValues = measures.values
	
	protected def getMeasure(measureName : String, data : Map[String,Any]) = {
		val measureVal = data.get(measureName)
		if (measureVal.isEmpty) None else Convert.toDouble(measureVal.get)
	}

	protected def getKeyComponent(dimName : String, data : Map[String,Any]) = {
		aggregation.cube.dimensions(dimName).key.ensure(data(dimName))
	}

	def toMap(includedMeasures : Iterable[String] = measures.keys) : Map[String,Any] = {
		Map(
			"key" -> key,
			"measures" -> measures.filter{ m => includedMeasures.toSeq.contains(m._1)}
			.map{ m => 
				Map(
					"name" -> m._1,
					"value" -> m._2
				)
			}
		)
	}

}