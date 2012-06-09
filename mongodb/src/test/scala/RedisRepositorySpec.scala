package org.wonkavision.redis

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers

import org.wonkavision.core._
import org.wonkavision.core.DimensionMember
import org.wonkavision.server.messages._
import org.wonkavision.core.filtering._
import org.wonkavision.core.AttributeType._

import akka.actor.ActorSystem

class RedisSpec extends Spec with BeforeAndAfter with ShouldMatchers {
	
  val system = ActorSystem("wonkavision")
  val redis = new Redis(system)
 
  describe("exec") {
    it("should execute a redis command and set a key") {
      redis.exec { redis =>
        redis.set("hi","ho")
        redis.get("hi") should equal (Some("ho"))
      }
    }
    it ("should save in one exec and read in another") {
      redis.exec { _.set("hi","ho") }
      redis.exec { _.get("hi") should equal (Some("ho"))}
    }
  }


}
 