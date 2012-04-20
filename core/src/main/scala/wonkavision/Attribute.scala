package org.wonkavision.core

import org.scala_tools.time.Imports._

import AttributeType._

case class Attribute(name : String, attributeType : AttributeType = AttributeType.String, default : Option[Any] = None) {

	def coerce(value : Any) = attributeType match {
		case Integer => Convert.coerce(value -> classOf[Long])
		case Decimal => Convert.coerce(value -> classOf[Double])
		case String => value.toString
		case Time => Convert.coerce(value -> classOf[DateTime])
	}

	def ensure(value : Any) = 
		if (value == null) getDefault else coerce(value)

	def getDefault() = {
		default.getOrElse(
			attributeType match {
				case Integer => 0
				case Decimal => 0.0
				case String => ""
				case Time => null	
			}
		)
	}
	
}