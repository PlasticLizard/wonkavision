package org.wonkavision.server

import com.typesafe.play.mini._


import org.wonkavision.server.messages._
import org.wonkavision.core.Cube
import org.wonkavision.core.filtering.MemberFilterExpression

object ApiHelper {
	
	val LIST_DELIMITER = "\\|"
	val AXIS_NAMES = List("columns","rows","pages","chapters","sections")

	def parseQuery(cubeName : String, aggregationName : String, qs : Map[String, Seq[String]]) = {

		val axes = parseAxes(qs)
		val measureNames = parseList(qs, "measures")
		val filterStrings = parseList(qs, "filters")

		CellsetQuery(
			cubeName = cubeName,
			aggregationName = aggregationName,
			axes = axes,
			measures = measureNames,
			filters = filterStrings.map(fs => MemberFilterExpression.parse(fs))
		)
	}

	def parseAxes(queryString : Map[String, Seq[String]]) = {
		AXIS_NAMES.map{axis => parseList(queryString, axis)}
			.takeWhile(_ != List())
	}

	def parseList(queryString : Map[String, Seq[String]], qsKey : String) = {
		param(queryString, qsKey).mkString("|").split(LIST_DELIMITER).toList.filter(_ != "")
	}

	def param(queryString : Map[String, Seq[String]], qsKey : String) = {
		queryString.getOrElse(qsKey, Seq())
	}

	def validateQuery(query : CellsetQuery) : Option[ObjectNotFound] = {
		if (!Cube.cubes.contains(query.cubeName))
			Some(ObjectNotFound("Cube", query.cubeName))
		else
			validateQuery(Cube.cubes(query.cubeName), query)
	}

	def validateQuery(cube : Cube, query : CellsetQuery) : Option[ObjectNotFound] = {
		val missingDims = query.dimensions.diff(cube.dimensionNames.toSeq)
		if (missingDims != Nil) {
			Some(ObjectNotFound("Dimension(s)", missingDims.mkString(", ")))
		} else if (!cube.aggregations.contains(query.aggregationName)) {
			Some(ObjectNotFound("Aggregation", query.aggregationName))
		} else { None }
	}
}