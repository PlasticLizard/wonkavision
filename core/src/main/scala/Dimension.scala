package org.wonkavision.core

import scala.collection.immutable.SortedSet

case class Dimension(
	name : String,
	keyAttribute : Option[Attribute] = None,
	captionAttribute : Option[Attribute] = None,
	sortAttribute : Option[Attribute] = None)(implicit val cube : Cube) {

	val fullname = cube.fullname + "!" + name

	def key = getAttribute("key")
	def caption = getAttribute("caption")
	def sort = getAttribute("sort")

	lazy val attributes = List("key","caption","sort").map(a=>getAttribute(a))

	def getAttribute(attrName : String) : Attribute = {
		val defaultAttr = Attribute(name)
		attrName match {
			case "key" => keyAttribute.getOrElse(defaultAttr)
			case "caption" => captionAttribute.getOrElse(getAttribute("key"))
			case "sort" => sortAttribute.getOrElse(getAttribute("caption"))
			case _ => Attribute(attrName)
		}
	}

	def createMember(memberData : Map[String,Any]) : DimensionMember = {
		new DimensionMember(memberData)(this)
	}

	def createMember(elements : (String,Any)*) : DimensionMember = {
		createMember(Map(elements:_*))
	}

}