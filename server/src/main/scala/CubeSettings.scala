package org.wonkavision.server

import com.typesafe.config.Config
import akka.actor.ActorSystem

object CubeSettings {

	def forCube(cubeName : String)(implicit system : ActorSystem) = {
		val path = "cube." + cubeName
		val main = system.settings.config
		val default = defaultCubeConfig(main, system)

		if (main.hasPath(path)) {
			new CubeSettings(main.getConfig(path).withFallback(default))
		} else {
			new CubeSettings(default)
		}
	}

	def defaultCubeConfig(config : Config, system : ActorSystem) = {
		val baseDefault = config.getConfig("wonkavision.default-cube")
		if (config.hasPath(system.name + ".default-cube")) {
			config.getConfig(system.name + ".default-cube").withFallback(baseDefault)
		} else {
			baseDefault
		}
	}
}

class CubeSettings(val config : Config) {
  val enabled = config.getBoolean("enabled")
  val dimensionRepoClassName = config.getString("dimension-repository.class")
  val dimensionRepoWorkerCount = config.getInt("dimension-repository.workers")

  val aggregationRepoClassName = config.getString("aggregation-repository.class")
  val aggregationRepoWorkerCount = config.getInt("dimension-repository.workers")
}