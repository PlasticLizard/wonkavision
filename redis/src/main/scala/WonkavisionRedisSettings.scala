package org.wonkavision.server.persistence

import com.typesafe.config.Config

class WonkavisionRedisSettings(val config : Config) {
  import config._

  val namespace = "wonkavision.redis"

  val Hostname = getString(namespace + ".hostname")
  val Port = getInt(namespace + ".port")
}