package org.wonkavision

import org.wonkavision.core.MapTransformation
import org.wonkavision.core.Attribute
import org.wonkavision.core.AttributeType._
import org.joda.time.DateTime

package object core {
	implicit def toOption(value : Any) : Option[Any] = Option(value)
	implicit def toOption(value : Int) : Option[Int] = Option(value)
	implicit def toOption(value : MapTransformation) : Option[MapTransformation] = Option(value)	
	implicit def toOption(value : Attribute) : Option[Attribute] = Option(value)
	import Conversions._
}