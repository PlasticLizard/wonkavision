package org.wonkavision.core

import FactAction._

case class FactEventBinding(
	eventPath : String,
	action : FactAction,
	cube : Cube,
	transformation : Option[MapTransformation] = None
) 