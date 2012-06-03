package org.wonkavision.core

import AttributeType._

object Conversions {
	implicit def toAttribute(name : String) = Attribute(name, AttributeType.String)
	implicit def toAttribute(nameAndType : (String, AttributeType)) = Attribute(nameAndType._1, nameAndType._2)
	implicit def toAttribute(nameTypeAndDefault : (String, AttributeType, Any)) = Attribute(nameTypeAndDefault._1, nameTypeAndDefault._2, Option(nameTypeAndDefault._3))
}