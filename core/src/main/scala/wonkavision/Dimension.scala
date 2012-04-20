package org.wonkavision.core

import scala.collection.immutable.SortedSet

case class Dimension(
	name : String,
	key : Option[Attribute] = None,
	caption : Option[Attribute] = None,
	sort : Option[Attribute] = None) {

	lazy val attributes = List("key","caption","sort").map(a=>getAttribute(a))

	def getAttribute(attrName : String) = {
		val defaultAttr = Attribute(name)
		attrName match {
			case "key" => key.getOrElse(defaultAttr)
			case "caption" => caption.orElse(key).getOrElse(defaultAttr)
			case "sort" => sort.orElse(caption).orElse(key).getOrElse(defaultAttr)
			case _ => Attribute(attrName)
		}
	}

}