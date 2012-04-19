package org.wonkavision.server.messages

case class CellsetQuery(
	cube : String,
	aggregation : String,
	axes : List[List[String]],
	measures : List[String],
	filters : List[String]
) {
	def dimensions = axes.flatten
}

abstract trait QueryResult
case class ObjectNotFound(what : String, name : String) extends QueryResult {
	def message = what + " " + name + " cannot be found"
}


case class Cellset extends QueryResult
