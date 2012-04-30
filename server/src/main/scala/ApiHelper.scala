package org.wonkavision.server

import collection.JavaConversions._

import org.wonkavision.server.messages._
import org.wonkavision.core.Cube
import org.wonkavision.core.filtering.MemberFilterExpression


object ApiHelper {
	
	val LIST_DELIMITER = "\\|"
	val AXIS_NAMES = List("columns","rows","pages","chapters","sections")

	def parseQuery(cubeName : String, aggregationName : String, queryParams : Map[String,List[String]]) : CellsetQuery = {

		implicit val params = queryParams
		val axes = parseAxes()
		val measureNames = parseList("measures")
		val filterStrings = parseList("filters")

		CellsetQuery(
			cubeName = cubeName,
			aggregationName = aggregationName,
			axes = axes,
			measures = measureNames,
			filters = filterStrings.map(fs => MemberFilterExpression.parse(fs))
		)
	}

	def parseAxes()(implicit params : Map[String,List[String]]) = {
		AXIS_NAMES.map{axis => parseList(axis)}
			.takeWhile(_ != List())
	}

	def parseList(qsKey : String)(implicit params : Map[String,List[String]]) = {
		params.getOrElse(qsKey, List()).mkString("|").split(LIST_DELIMITER).toList.filter(_ != "")
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

	// def parseQueryParams(queryString : String) : Map[String,List[String]] = {
	// 	val decoder = new QueryStringDecoder("?"+queryString)
	// 	val elements = decoder.getParameters().iterator.map{ entry =>
	// 		(entry._1, entry._2.asInstanceOf[java.util.ArrayList[String]].toList)
	// 	}
	// 	Map(elements.toSeq:_*)
	// }
}