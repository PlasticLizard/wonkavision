package org.wonkavision.core

import scala.collection.immutable.SortedSet

case class Dimension(
	name : String,
	key : Option[Attribute] = None,
	caption : Option[Attribute] = None,
	sort : Option[Attribute] = None) {

	def getAttribute(name : String) = {
		val defaultAttr = Attribute(name)
		name match {
			case "key" => key.getOrElse(defaultAttr)
			case "caption" => caption.orElse(key).getOrElse(defaultAttr)
			case "sort" => sort.orElse(caption).orElse(key).getOrElse(defaultAttr)
			case _ => Attribute(name)
		}
	}

}