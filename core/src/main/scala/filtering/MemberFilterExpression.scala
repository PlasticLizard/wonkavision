package org.wonkavision.core.filtering

import org.scala_tools.time.Imports._

import org.wonkavision.core.MemberType
import org.wonkavision.core.MemberType._
import org.wonkavision.core.Convert
import FilterOperator._

object MemberFilterExpression {
	var ARY = "^\\[(.*)\\]$".r
	val DELIM_STR = "^(\\'|\\\")(.*)(\\'|\\\")$".r
	val INT = "(\\A[+-]?\\d+?\\Z)".r
	val DEC = "(\\A[+-]?(\\d+)?(\\.\\d+)\\Z)".r
	val TIME = "^time\\((.*)\\)$".r

	def parse(filterString : String) : MemberFilterExpression = {
		val parts = filterString.split("::")
		val memberType = MemberType.withName(parts(0).capitalize)
		val memberName = parts(1)
		val attributeName = parts(2)
		val operator = FilterOperator.withName(parts(3).capitalize)
		val vals = parseValues(parts(4))
		new MemberFilterExpression(memberType,memberName,attributeName,operator,vals)
	}		

	private def parseValues(valString : String) : List[String] = {
		valString match {
			case DELIM_STR(_,str,_) => List(str)
			case INT(i) => List(i)
			case DEC(d,_,_) => List(d)
			case TIME(t) => List(t)
			case ARY(ary) => {
				val list = ary.split(",").toList.map(v => parseValues(v))
				list.flatten
			}
			case _ => List(valString)
		} 
	}

}

class MemberFilterExpression (
	val memberType : MemberType,
	val memberName : String,
	val attributeName : String,
	operator : FilterOperator,
	values : List[Any]) extends FilterExpression(operator, values) {

	override def toString() = {
		List(
			memberType.toString.toLowerCase,
			memberName,
			attributeName,
			super.toString
		).mkString("::")
	}

}