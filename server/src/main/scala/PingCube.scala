package org.wonkavision.server.cubes

import org.wonkavision.core._
import AttributeType._

class PingCube extends Cube("ping") {
	
	dimension (
		name = "ding",
		key = "id" -> Integer,
		caption = "name"
	)

	dimension (
		name = "dong",
		key = "id" -> Integer,
		caption = "name"
	)

	aggregation (
		name = "pong"
	)

}