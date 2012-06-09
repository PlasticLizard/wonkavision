package org.wonkavision.mongodb

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers

import org.wonkavision.core._
import org.wonkavision.core.DimensionMember
import org.wonkavision.server.messages._
import org.wonkavision.core.filtering._
import org.wonkavision.core.AttributeType._

import akka.actor.ActorSystem

class MongoDbSpec extends Spec with BeforeAndAfter with ShouldMatchers {
	
  val system = ActorSystem("wonkavision")
  val mongo = new MongoDb(system)
 
 


}
 