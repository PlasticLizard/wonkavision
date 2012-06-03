package org.wonkavision.server.test.cubes

import org.wonkavision.core._
import FactAction._
import org.wonkavision.server.Environment
import Conversions._

class TestCube extends Cube("testcube") {
	
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
		name = "testaggregation",
		measures = List("count", "incoming", "outgoing"),
		_.aggregateAll
	)

}

class TestEnv extends Environment