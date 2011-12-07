package org.wonkavision.core

case class Event(
	path : String,
	data : Map[String, Any]
)