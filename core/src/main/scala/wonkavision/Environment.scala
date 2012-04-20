package org.wonkavision.core

object Environment extends Enumeration {
	type Environment = Value
	val Test, Development, Production, Staging = Value
}

trait Environment {

	private var currentEnv : Environment.Value = _
	def environment = currentEnv

	def initialize(env : Environment.Value) {
		currentEnv = 	env
		configure(env)
	}

	def configure : PartialFunction[Environment.Value, Unit] = {
		case _ =>
	}
	
}