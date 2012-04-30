import play.api._
import play.api.libs.concurrent.Akka
import akka.actor.{Props, Actor}
import play.api.Play

import org.wonkavision.server.Wonkavision

object Global extends com.typesafe.play.mini.Setup(org.wonkavision.server.App) {
	override def onStart(app : Application) {
		Wonkavision.startNew("wonkavision")    	
	}

	override def onStop(app : Application) {
	}
}
