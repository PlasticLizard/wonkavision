package org.wonkavision.server.cubes

import org.wonkavision.core._

class NullCube extends Cube("null.cube") {
	
	dimension (
		name = "null.dimension",
		key = "id",
		caption = "name",
		sort = "name"
	)

	aggregation (
		name = "null.aggregation"
	)

}