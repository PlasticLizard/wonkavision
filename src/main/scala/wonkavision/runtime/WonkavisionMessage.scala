package org.wonkavision.runtime

sealed trait WonkavisionMessage

case class RawEvent(
	eventPath : String,
	eventData : Array[Byte] ) extends WonkavisionMessage

case class Event(
	eventPath : String,
	eventData : Map[String, Any] ) extends WonkavisionMessage	

