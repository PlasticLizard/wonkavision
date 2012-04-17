// package org.wonkavision.runtime

// import akka.actor.Actor

// import org.wonkavision.core.Environment

// object Runtime {

// 	private var currentRuntime : Runtime = _
// 	def current = currentRuntime

// 	def initialize(env: Environment.Value) {
// 		currentRuntime = new Runtime(env)
// 	}
	
// }

// class Runtime(env : Environment.Value) extends Environment {
// 	initialize(env)

// 	val aggregationServiceKey = "wonkavision.aggregation"
// 	val storageServiceKey = "wonkavision.storage"
// 	val apiServiceKey = "wonkavision.api"

// 	def receiveEvent(event : Event) {
// 		Actor.registry.actorsFor(aggregationServiceKey).foreach( _ ! event)
// 	}

// }