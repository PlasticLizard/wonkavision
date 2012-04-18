package org.wonkavision.server

import com.typesafe.play.mini._

import org.wonkavision.server.messages.Query

object ApiHelper {
	
	val LIST_DELIMITER = "|"

	def parseQuery(cubeName : String, aggregationName : String, qs : String) = {

		val axes = parseAxes(qs)
		val measureNames = parseList(qs, "measures")
		val filterStrings = parseList(qs, "filters")

		Query(
			cube = cubeName,
			aggregation = aggregationName,
			axes = axes,
			measures = measureNames,
			filters = filterStrings
		)
	}

	def parseAxes(queryString : String) = {
		List()
	}

	def parseList(queryString : String, qsKey : String) = {
		QueryString(queryString, qsKey)
			.getOrElse("").toString.split(LIST_DELIMITER).filter{_ != ""}
			.toList
	}
}