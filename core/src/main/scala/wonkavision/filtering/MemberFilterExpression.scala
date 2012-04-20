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

	def parse(filterString : String) : MemberFilterExpression[_] = {
		val parts = filterString.split("::")
		val memberType = MemberType.withName(parts(0).capitalize)
		val memberName = parts(1)
		val attributeName = parts(2)
		val operator = FilterOperator.withName(parts(3).capitalize)
		val valString = parts(4)
		createTypedExpression(memberType,memberName,attributeName,operator,valString)
	}	

	private def createTypedExpression(mType: MemberType, name: String, attribute: String,  op : FilterOperator, valString : String) = {
		val (vType, list) = detectType(valString)
		vType match {
			case x if x == classOf[String] => new MemberFilterExpression(mType,name,attribute,op,list.map(s => Convert.toString(s).get))
			case x if x == classOf[Int] => new MemberFilterExpression(mType,name,attribute,op,list.map(s => Convert.toInt(s).get))
			case x if x == classOf[Long] => new MemberFilterExpression(mType,name,attribute,op,list.map(s => Convert.toLong(s).get))
			case x if x == classOf[Double] => new MemberFilterExpression(mType,name,attribute,op,list.map(s => Convert.toDouble(s).get))
			case x if x == classOf[DateTime] => new MemberFilterExpression(mType,name,attribute,op,list.map(s => Convert.toDate(s).get))
		}		
	}

	private def detectType(valString : String) : (Class[_], List[String]) = {
		valString match {
			case DELIM_STR(_,str,_) => (classOf[String], List(str))
			case INT(i) => {
					if (i.toLong > Integer.MAX_VALUE) {
						(classOf[Long], List(i))
					} else {
						(classOf[Int], List(i))
					}					
				} 
			case DEC(d,_,_) => (classOf[Double], List(d))
			case TIME(t) => (classOf[DateTime], List(t))
			case ARY(ary) => {
				val list = ary.split(",").toList.map(v => detectType(v))
				val (vType,_) = list.head
				(vType, list.flatMap(_._2))
			}
			case _ => (classOf[String], List(valString))
		} 
	}

}

class MemberFilterExpression[T : Ordering](
	val memberType : MemberType,
	val memberName : String,
	val attributeName : String,
	operator : FilterOperator,
	values : List[T]) extends FilterExpression[T](operator, values) {

	override def toString() = {
		List(
			memberType.toString.toLowerCase,
			memberName,
			attributeName,
			super.toString
		).mkString("::")
	}

}