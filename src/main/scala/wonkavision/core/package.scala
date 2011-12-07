package org.wonkavision

import org.wonkavision.core.MapTransformation

package object core {

	implicit def toOption(value : Any) : Option[Any] = Option(value)
	implicit def toOption(value : Int) : Option[Int] = Option(value)
	implicit def toOption(value : MapTransformation) : Option[MapTransformation] = Option(value)
}