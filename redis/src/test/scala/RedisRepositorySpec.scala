package org.wonkavision.redis

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers

import org.wonkavision.core._
import org.wonkavision.core.DimensionMember
import org.wonkavision.server.messages._
import org.wonkavision.core.filtering._
import org.wonkavision.core.AttributeType._
import org.wonkavision.server.Wonkavision

class RedisRepositorySpec extends Spec with BeforeAndAfter with ShouldMatchers {
	
  val wv = Wonkavision.startNew("wonkavision")
  object RedisRepo extends RedisRepository(wv) {
    def execCmd[T] = exec[T]_
  }
 
  describe("exec") {
    it("should execute a redis command and set a key") {
      RedisRepo.execCmd { redis =>
        redis.set("hi","ho")
        redis.get("hi") should equal (Some("ho"))
      }
    }
    it ("should save in one exec and read in another") {
      RedisRepo.execCmd { _.set("hi","ho") }
      RedisRepo.execCmd { _.get("hi") should equal (Some("ho"))}
    }
  }


}
 