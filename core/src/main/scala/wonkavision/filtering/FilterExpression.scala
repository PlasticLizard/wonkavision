package org.wonkavision.core.filtering

import org.joda.time.format.ISODateTimeFormat
import org.scala_tools.time.Imports._

import org.wonkavision.core.Convert
import FilterOperator._
import Ordering.Implicits._

class FilterExpression(val operator:FilterOperator, val values : List[Any]){
	
	def this(operator: FilterOperator, value : Some[Any]) = this(operator, List(value.get))
	
	
	def matches[T:Ordering](data : T) = {
		val vals = values.map(v => Convert.coerce(v -> data.getClass).asInstanceOf[T])
		if (operator == In) {
			vals.contains(data)
		} else {
			vals.forall { value =>
				operator match {
					case Gt => data > value
					case Gte => data >= value
					case Lt => data < value
					case Lte => data <= value
					case Eq => data == value
					case In => data == value
					case Ne => data != value
					case Nin => data != value
					case _ => false
				}
			}
		}		
	}

	val delimitedString = {
		if (values.size > 1 || operator == In || operator == Nin) {
			"[" + values.map{v => delimitedValue(v)}.mkString(",") + "]"
		} else if (values.size > 0) {
			delimitedValue(values.head)
		} else {
			"nil"
		}
	}

	def delimitedValue(value : Any) = {
		value match {
			case _ : DateTime => "time(" + value + ")"
			case _ => value.toString
		}
	}

	override def toString() = toString("::")
	
	def toString(delim : String) = {
		operator.toString.toLowerCase() + delim + delimitedString
	}

	override def equals(other : Any) : Boolean =
		other.toString == toString

	def canEqual(other : Any) : Boolean = true

	override def hashCode : Int = toString.hashCode

}