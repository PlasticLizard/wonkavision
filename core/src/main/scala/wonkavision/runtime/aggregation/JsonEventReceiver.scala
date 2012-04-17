// package org.wonkavision.runtime.aggregation

// import akka.actor.Actor._
// import akka.actor.Actor
// import akka.event.EventHandler

// import net.liftweb.json._

// import org.wonkavision.runtime.{RawEvent, Event, Runtime}

// class JsonEventReceiver(implicit val runtime : Runtime) extends Actor {
	
// 	override def receive = {
// 		case RawEvent(path, data) =>
// 		  dispatch(path, parseJson(new String(data)))
// 	}

// 	def dispatch(path : String, data : Map[String, Any]) {
// 		runtime.receiveEvent(Event(path, data))
// 	}

// 	def parseJson(json : String) = {
// 		parse(json).values.asInstanceOf[Map[String, Any]]
// 	}

// }