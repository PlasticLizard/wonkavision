package org.wonkavision.core

import scala.collection.mutable.Stack
import scala.collection.mutable.HashMap
import org.joda.time.format.ISODateTimeFormat
import org.scala_tools.time.Imports._

trait MapTransformation {

	implicit def toOption(value : Any) : Option[Any] = Option(value)
	implicit def toOption(value : Int) : Option[Int] = Option(value)

	val ISO_DAY = "yyyy-MM-dd"
	val ISO_MONTH = "yyyy-MM"

	type Source = Map[String, Any]
	type Target = HashMap[String, Any]
	val EmptySource : Source = new scala.collection.immutable.HashMap

	val sourceStack = new Stack[Source]
	val targetStack = new Stack[Target]

	def source = sourceStack.head
	def target = targetStack.head

	def source(idx : Int) = sourceStack(idx)
	def target(idx : Int) = targetStack(idx)

	def parentSource = source(1)
	def parentTarget = target(1)

	def source(sourcePath : String*) = {
		findNestedSource(sourcePath.toList)
	}

	def map : Unit

	def execute( source: Source, t: Target = new Target, m: => Unit = map ): Target =
		to(t){ from(Some(source)){ m } } 

	def include(transform : MapTransformation, src : Source = source) {
		transform.execute(src, target)
	}

	def from(src: Option[Source])
		       (f: => Unit) = {

		var context = src.getOrElse(source)
		withContext[Source](sourceStack, context, f)
	}

	def to(target: Target)(f: => Unit) =
		withContext[Target](targetStack, target, f)
	
	def child(childName: String, source: Any)(f: => Unit) {
		child(childName, Some(source.asInstanceOf[Source]))(f)
	}

	def child(childName: String,
		        src: Option[Source] = None)(f: => Unit) {
		
		val s = src.getOrElse( source.getOrElse(childName, EmptySource) ).asInstanceOf[Source]        	
		
		target(childName) = to( new Target ) {
			from(Some(s)){f}
		}
	}

	def int(fieldName: String,
		      value: Option[Any] = None,
		      default: Option[Any] = None ) = {
		       
		setTarget(fieldName, getInt(fieldName, value, default))
	}

	def ints(fieldNames : String*) = fieldNames.foreach(int(_))

	def long(fieldName: String,
		       value: Option[Any] = None,
		       default: Option[Any] = None ) = {

		setTarget(fieldName, getLong(fieldName, value, default))
	}
	def longs(fieldNames: String*) = fieldNames.foreach(long(_))

	def double(fieldName: String,
		         value: Option[Any] = None,
		         default: Option[Any] = None) = {

		setTarget(fieldName, getDouble(fieldName, value, default))
	}
	def doubles(fieldNames : String*) = fieldNames.foreach(double(_))

  def string(fieldName: String,
	           value: Option[Any] = None,
	           default: Option[Any] = None) = {

  	setTarget(fieldName, getString(fieldName, value, default) )
  }	
	def strings(fieldNames: String*) = fieldNames.foreach(string(_))

	def date(fieldName: String,
				   value: Option[Any] = None,
				   default: Option[Any] = None) = {
				   	
		setTarget(fieldName, getDate(fieldName, value, default))	
	}
	def dates(fieldNames: String*) = fieldNames.foreach(string(_))

	def dateString(fieldName: String,
		             value: Option[Any] = None,
		             default: Option[Any] = None,
		             format: String = ISO_DAY) = {
		
		setTarget(fieldName, getDateString(fieldName,value,default,format))
	}

	def bool(fieldName: String,
					 value: Option[Any] = None,
					 default: Option[Any] = None) = {
					 	
		setTarget(fieldName, getBool(fieldName, value, default))	
	}
	def bools(fieldNames: String*) = fieldNames.foreach(bool(_))

	def count(fieldName : String,
						inc : Int = 1,
						default : Option[Int] = Some(0))
						(pred : => Boolean ) {
							
		val c = if (pred) inc else default.getOrElse(null)
		int(fieldName, c)
	}

	def formatDate(date: DateTime, dateFormat: String) =
		DateTimeFormat.forPattern(dateFormat).print(date)

	def formatDate(date: Option[DateTime], dateFormat: String) : String =
		if (date.isEmpty) null else formatDate(date.get, dateFormat)
	
	
	def getString(fieldName: String, value: Option[Any] = None, default: Option[Any] = None) =
		Convert toString getValue(fieldName, value, default)

	def getInt(fieldName: String, value: Option[Any] = None, default: Option[Any] = None) =
		Convert toInt getValue(fieldName, value, default)

	def getLong(fieldName: String, value: Option[Any] = None, default: Option[Any] = None) =
		Convert toLong getValue(fieldName, value, default)

	def getDouble(fieldName : String, value: Option[Any] = None, default: Option[Any] = None) =
		Convert toDouble getValue(fieldName, value, default)

	def getDate(fieldName : String, value: Option[Any] = None, default: Option[Any] = None) =
		Convert toDate getValue(fieldName, value, default)

	def getBool(fieldName : String, value: Option[Any] = None, default: Option[Any] = None) = 
		Convert toBool getValue(fieldName, value, default)
	
	def getDateString(fieldName : String, value: Option[Any] = None, default: Option[Any] = None, format: String = "yyyy-MM-dd") = {
		val date = getDate(fieldName, value, default)
		var dateString : String = null
		for(d <- date) {
			dateString = formatDate(d, format)
		}
		Option(dateString)
	}

	private def getValue(fieldName: String,
		                   proposedValue: Option[Any],
		                   defaultValue: Option[Any] = None) : Any = {
		
		var value = source.getOrElse(fieldName, null)
		if (value == null || value.toString == "") value = defaultValue.getOrElse(null)

		proposedValue getOrElse value		
	}

	private def setTarget(fieldName : String,
		                    value: Option[Any],
		                    default: Any = null) : Any = {

		target(fieldName) = value.getOrElse(default)
		target(fieldName)	
	}

	private def withContext[T](stack: Stack[T],
		                         ctx: T,
		                         f: => Unit):T = {

		stack.push(ctx); f; stack.pop
	}

	private def findNestedSource(pathElements : List[String],
		                           current : Source = source) : Source = {
		if (pathElements == Nil) current
		else {
			val next = current.getOrElse(pathElements.head, null).asInstanceOf[Source]
			findNestedSource(pathElements.tail, next)
		}
		
	}
	
}