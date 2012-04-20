package org.wonkavision.core

import AttributeType._

case class Attribute(name : String, attributeType : AttributeType = AttributeType.String) {

	def convert(value : Any) = value
}