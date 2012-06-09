package org.wonkavision.mongodb

import com.typesafe.config.Config

class WonkavisionMongoDbSettings(val config : Config) {
  import config._

  val namespace = "wonkavision.mongodb"

  val DatabaseName = getString(namespace + ".database-name")
  val Hostname = getString(namespace + ".hostname")
  val Port = getInt(namespace + ".port")
}