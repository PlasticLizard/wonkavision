import play.api._
import play.api.libs.concurrent.Akka
import akka.actor.{Props, Actor}
import play.api.Play

import org.wonkavision.core.Cube
import org.wonkavision.server.CubeLoader

import com.typesafe.config.ConfigFactory
import org.reflections.scanners.SubTypesScanner
import scala.collection.JavaConversions._

import org.wonkavision.server.actors.WonkavisionActor

object Global extends com.typesafe.play.mini.Setup(org.wonkavision.server.App) {
	override def onStart(app : Application) {
    	val cubePackages = Play.current.configuration.underlying.getList("wonkavision-server.cube.packages").unwrapped().map(_.toString)
    	Cube register new CubeLoader(cubePackages:_*).cubes
	}

	override def onStop(app : Application) {
	}
}
