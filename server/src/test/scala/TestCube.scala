package org.wonkavision.server.test.cubes

import org.wonkavision.core._
import FactAction._

class TestCube extends Cube("A Cube Of Testing") {
	
	dimension (
		name = "team",
		key = "id",
		caption = "name",
		sort = "name"
	)

	dimension (
		name = "status",
		key = "status",
		caption = "status",
		sort = "sort"
	)
	
	sum ( "incoming",
		  "outgoing"
	)	

	aggregation (
		name = "An Aggregation",
		measures = List("count", "incoming", "outgoing"),
		_.aggregateAll
	)

}