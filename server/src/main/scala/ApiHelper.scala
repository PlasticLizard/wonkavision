package org.wonkavision.server

import com.typesafe.play.mini._
import collection.JavaConversions._

import org.wonkavision.server.messages._
import org.wonkavision.core.Cube

object ApiHelper {
	
	val LIST_DELIMITER = "\\|"
	val AXIS_NAMES = List("columns","rows","pages","chapters","sections")

	def parseQuery(cubeName : String, aggregationName : String, qs : String) = {

		val axes = parseAxes(qs)
		val measureNames = parseList(qs, "measures")
		val filterStrings = parseList(qs, "filters")

		CellsetQuery(
			cube = cubeName,
			aggregation = aggregationName,
			axes = axes,
			measures = measureNames,
			filters = filterStrings
		)
	}

	def parseAxes(queryString : String) = {
		AXIS_NAMES.map{axis => parseList(queryString, axis)}
			.takeWhile(_ != List())
	}

	def parseList(queryString : String, qsKey : String) = {
		param(queryString, qsKey).mkString("|").split(LIST_DELIMITER).toList.filter(_ != "")
	}

	def param(queryString : String, qsKey : String) = {
		QueryString(queryString, qsKey)
			.getOrElse(new java.util.ArrayList[String]())
			.asInstanceOf[java.util.ArrayList[String]].toList
	}

	def validateQuery(query : CellsetQuery) : Option[ObjectNotFound] = {
		if (!Cube.cubes.contains(query.cube))
			Some(ObjectNotFound("Cube", query.cube))
		else
			validateQuery(Cube.cubes(query.cube), query)
	}

	def validateQuery(cube : Cube, query : CellsetQuery) : Option[ObjectNotFound] = {
		val missingDims = query.dimensions.diff(cube.dimensionNames.toSeq)
		if (missingDims != Nil) {
			Some(ObjectNotFound("Dimensions", missingDims.mkString(", ")))
		} else if (!cube.aggregations.contains(query.aggregation)) {
			Some(ObjectNotFound("Aggregation", query.aggregation))
		} else { None }
	}
}