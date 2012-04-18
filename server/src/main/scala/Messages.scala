package org.wonkavision.server.messages

case class Query(
	cube : String,
	aggregation : String,
	axes : List[List[String]],
	measures : List[String],
	filters : List[String]
)

abstract class QueryResult

case class CubeNotFound(cubeName : String) extends QueryResult

case class Cellset extends QueryResult