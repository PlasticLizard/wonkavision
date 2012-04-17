// package org.wonkavision.runtime.aggregation

// import akka.actor.Actor
// import akka.config.Supervision._

// import org.wonkavision.runtime.{Event, Runtime}
// import org.wonkavision.core.{Cube, FactEventBinding}

// class AggregationService(val cubes : Iterable[Cube])(implicit val runtime : Runtime) extends Actor {
// 	self.id = runtime.aggregationServiceKey
// 	self.faultHandler = OneForOneStrategy(List(classOf[Throwable]), 10, 1000)
// 	self.lifeCycle = Permanent

// 	val handlers = initializeHandlers

// 	def receive = {
// 		case evt : Event => dispatch(evt)
// 	}

// 	def initializeHandlers = {
// 		for ( cube <- cubes; evt <- cube.events ) yield (evt, handlerFor(evt))
// 	}

// 	def handlerFor(binding : FactEventBinding) = {
// 		val handler = Actor.actorOf(new Actor {def receive = {case _=>}})
// 		self startLink handler
// 		handler
			
// 	}	

// 	def dispatch(evt : Event) =
// 		for ( (binding, handler) <- handlers if shouldHandle( binding, evt ) ) {
// 			handler ! evt
// 		}

// 	def shouldHandle(binding : FactEventBinding, event : Event) = {
// 		binding.eventPath == event.eventPath
// 	}


// }