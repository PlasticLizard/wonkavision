package org.wonkavision.server

import org.wonkavision.core.Cube

import com.typesafe.config.ConfigFactory
import org.reflections.scanners.SubTypesScanner
import scala.collection.JavaConversions._

import akka.actor.{Props, ActorSystem, Actor}
import akka.pattern.ask
import akka.pattern.pipe
import akka.util.Timeout
import akka.util.duration._
import akka.dispatch.{Await, Future}

import org.wonkavision.server.actors.WonkavisionActor
import org.wonkavision.server.messages._
import org.wonkavision.server.actors.WonkavisionActor
import org.wonkavision.server.cubes._


object Wonkavision {
	val instances : scala.collection.mutable.Map[String,Wonkavision] = scala.collection.mutable.Map()

	def createActorSystem(appName : String) = {
		val baseConfig = ConfigFactory.load()
		ActorSystem(appName, baseConfig.getConfig(appName).withFallback(baseConfig))
	}

	def startNew(appName : String = "wonkavision") = {
		val wv = new Wonkavision(appName, createActorSystem(appName))
		instances += appName -> wv
		wv
	}

	def apply(appName : String) = instances.get(appName)
}

class Wonkavision(val appName : String, val system : ActorSystem) {
	
	def config = system.settings.config
	lazy val dispatcher = system.actorFor("akka://" + appName + "/user/dispatcher")
	initializeApp()

	def initializeApp(){
		val cubePackages = config.getStringList("cube.packages")
    	Cube register new CubeLoader(cubePackages:_*).cubes
    	
    	system.actorOf(Props(new WonkavisionActor(Cube.cubes.values)), "dispatcher")

    	if (config.getBoolean("ping.cube.enabled")) {
    		PingCube.initialize(dispatcher)   		
    	}

	}


	
	
}