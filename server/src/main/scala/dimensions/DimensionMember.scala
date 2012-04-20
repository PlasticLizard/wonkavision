package org.wonkavision.server.dimensions

import org.wonkavision.core.Dimension
import org.wonkavision.core.Attribute

case class DimensionMember(dimension : Dimension, attributeValues : Map[String,Any]) {

	def attributeValue(name : String) = {
		val attr = dimension.getAttribute(name)
		val rawVal = attributeValues(attr.name)
		attr.convert(rawVal)
	}
}