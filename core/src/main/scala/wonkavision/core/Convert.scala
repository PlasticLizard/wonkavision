package org.wonkavision.core

import scala.reflect.Manifest
import scala.math.round
import org.scala_tools.time.Imports._
import org.joda.time.format.ISODateTimeFormat

object Convert {
	
	def toString(value : Any) : Option[String] =
		if (value == null) None else Some(value.toString)

	def toInt(value : Any) : Option[Int] = {
		if (value == null) return None
		val converted : Int = value match {
		  case v:Long if (v.asInstanceOf[Int] != v) => 
		  	throw new IllegalArgumentException("Cannot convert " + v + "int an Int because it is too big")
		  case v:Long => v.asInstanceOf[Int]
		  case v:Int => v.asInstanceOf[Int]
		  case v:Double => round(v.asInstanceOf[Double]).toInt
		  case _ => round(value.toString.toFloat)
		}
		Option(converted)
	}

	def toLong(value : Any) : Option[Long] = {
		if (value == null) return None
		val converted : Long = value match {
			case v:Int => v.asInstanceOf[Long]
			case v:Long => v.asInstanceOf[Long]
			case v:Double => round(v.asInstanceOf[Double])
			case _ => round(value.toString.toFloat)
		}
		Option(converted)
	}

	def toDouble(value : Any) : Option[Double] = {
		if (value == null) return None
		val converted : Double = value match {
			case v:Int => v.asInstanceOf[Int].toDouble
			case v:Long => v.asInstanceOf[Long].toDouble
			case v:Double => v.asInstanceOf[Double]
			case _ => value.toString.toDouble
		}
		Option(converted)
	}

	def toDate(value : Any) : Option[DateTime] = {
		if (value == null) return None
		val converted : DateTime = value match {
			case v:DateTime => v
			case _ => ISODateTimeFormat.dateTimeParser().parseDateTime(value.toString)
		}
		Option(converted)
	}

	def toBool(value: Any) : Option[Boolean] = {
		if (value == null) return None
		val converted : Boolean = value match {
			case v:Boolean => v.asInstanceOf[Boolean]
			case _ => value.toString.toBoolean
		}
		Option(converted)
	}

}