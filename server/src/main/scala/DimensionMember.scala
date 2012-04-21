package org.wonkavision.server

import org.wonkavision.core.Dimension
import org.wonkavision.core.Attribute
import org.wonkavision.core.filtering.MemberFilterExpression

class DimensionMember(attributeMap : Map[String,Any])(implicit val dimension : Dimension) {
	
	val attributeValues = extractAttributeValues(attributeMap)

	def key = apply("key").get
	def caption = apply("caption").get
	def sort = apply("sort").get
	
	def at(idx : Int) = {
		if (idx < attributeValues.size) Some(attributeValues(idx)) else None
	}

	def apply(name : String) = {
		name match {
			case "key" => at(0)
			case "caption" => at(1)
			case "sort" => at(2)
			case _ => 			
				at( dimension.attributes.indexWhere(_.name == name) )
		}	
	}

	def matches(filters : List[MemberFilterExpression]) : Boolean = {
		filters.forall(matches(_))
	}

	def matches(filter : MemberFilterExpression) = {
		apply(filter.attributeName).exists(filter.matches(_))
	}

	private def extractAttributeValues(attrMap : Map[String, Any]) = {
		val converted = dimension.attributes.map{ attr =>
			val rawVal = attrMap.getOrElse(attr.name, null)
			attr.ensure(rawVal)
		}
		Vector(converted:_*)
	}
}