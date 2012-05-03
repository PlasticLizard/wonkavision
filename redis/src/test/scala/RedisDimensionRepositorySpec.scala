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

import akka.dispatch.Await
import akka.util.duration._

class RedisDimensionRepositorySpec extends Spec with BeforeAndAfter with ShouldMatchers {
	
	implicit val cube = new Cube("hi")
	implicit val dim = Dimension("dim", Attribute("k", Integer), Attribute("c"))
  implicit val wv = Wonkavision.startNew("wonkavision")

	var memberData : List[DimensionMember] = _
  var repo : RedisDimensionRepository = _

  List(
		Map("k" -> 1, "c" -> "a"),
		Map("k" -> 2, "c" -> "b"),
		Map("k" -> 3, "c" -> "c")
	)	

	before {
    memberData = List(
      dim.createMember(Map("k" -> 1, "c" -> "a")),
      dim.createMember(Map("k" -> 2, "c" -> "b")),
      dim.createMember(Map("k" -> 3, "c" -> "c"))
    ) 

    repo = new RedisDimensionRepository(dim)
    Await.result(repo.put(memberData), 1 second)
  }

	describe("get") {
  	it("should return the selected member") {
  		Await.result(repo.get("1"), 1 second).get.key should equal (1)    		
  	}  
  	it ("should return the selected") {
  		Await.result(repo.get(1), 1 second).get.key should equal (1)
  		Await.result(repo.get(2), 1 second).get.key should equal (2)
  		Await.result(repo.get(3), 1 second).get.key should equal (3)
  	}  
  	it ("should return none if not found") {
  		Await.result(repo.get(4), 1 second) should equal (None)
  	}
	}

	describe("all") {
		it ("should return the converted members") {
			val members = Await.result(repo.all, 1 second).toSeq
			members.size should equal(3)
			members(0).key should equal (1)
			members(0).caption should equal ("a")
			members(1).key should equal (2)
			members(1).caption should equal ("b")
			members(2).key should equal(3)
			members(2).caption should equal("c")
		}
	}

  describe("put") {
    it ("should add the member to the repo") {
      Await.result(repo.put(new DimensionMember(Map("k" -> 4, "c" -> "d"))), 1 second)
      Await.result(repo.get(4), 1 second).get.key should equal (4)
    }
    it ("should convert the key to the appropriate type"){
      Await.result(repo.put(new DimensionMember(Map("k"->"4", "c"->"d"))), 1 second)
      Await.result(repo.get(4), 1 second).get.key should equal (4)
    }
  }

  describe("delete"){
    it ("should remove the specified member") {
      Await.result(repo.get(1), 1 second) should not equal(None)
      Await.result(repo.delete(1), 1 second)
      Await.result(repo.get(1), 1 second) should equal (None)
    }
  }

  describe("purge"){
    it("should clear all items"){
      Await.result(repo.purge(), 1 second)
      Await.result(repo.all(), 1 second).size should equal(0)
    }
  }

}
 