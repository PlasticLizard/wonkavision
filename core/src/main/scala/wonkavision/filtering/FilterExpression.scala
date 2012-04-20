package org.wonkavision.core.filtering

import org.joda.time.format.ISODateTimeFormat
import org.scala_tools.time.Imports._

import FilterOperator._
import Ordering.Implicits._

class FilterExpression[T : Ordering](val operator:FilterOperator, val values : List[T]){
	
	def this(operator: FilterOperator, value : Some[T]) = this(operator, List(value.get))
	
	def matches(data : Any) = {
		matchesValues(data.asInstanceOf[T])
	}

	def matchesValues(data : T) = {
		if (operator == In) {
			values.contains(data)
		} else {
			values.forall { value =>
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

	def delimitedValue(value : T) = {
		value match {
			case _ : String => "'" + value + "'"
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