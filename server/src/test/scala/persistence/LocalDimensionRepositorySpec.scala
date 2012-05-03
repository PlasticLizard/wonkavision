package org.wonkavision.server.persistence

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers

import org.wonkavision.core._
import org.wonkavision.core.DimensionMember
import org.wonkavision.server.messages._
import org.wonkavision.core.filtering._
import org.wonkavision.core.AttributeType._

import akka.dispatch.{Await, ExecutionContext}
import akka.util.duration._
import akka.actor.ActorSystem

class LocalDimensionRepositorySpec extends Spec with BeforeAndAfter with ShouldMatchers {
	
	implicit val cube = new Cube("hi")
	implicit val dim = Dimension("dim", Attribute("k", Integer), Attribute("c"))
  val system  = ActorSystem("test")

	var memberData : List[Map[String,Any]] = _
  var repo : LocalDimensionRepository = _
  List(
		Map("k" -> 1, "c" -> "a"),
		Map("k" -> 2, "c" -> "b"),
		Map("k" -> 3, "c" -> "c")
	)	

	before {
    memberData = List(
      Map("k" -> 1, "c" -> "a"),
      Map("k" -> 2, "c" -> "b"),
      Map("k" -> 3, "c" -> "c")
    ) 

    repo = new LocalDimensionRepository(dim, system)
    repo.loadData(memberData)
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
      repo.put(new DimensionMember(Map("k" -> 4, "c" -> "d")))
      Await.result(repo.get(4), 1 second).get.key should equal (4)
    }
    it ("should convert the key to the appropriate type"){
      repo.put(new DimensionMember(Map("k"->"4", "c"->"d")))
      Await.result(repo.get(4), 1 second).get.key should equal (4)
    }
  }

  describe("delete"){
    it ("should remove the specified member") {
      Await.result(repo.get(1), 1 second) should not equal(None)
      repo.delete(1)
      Await.result(repo.get(1), 1 second) should equal (None)
      Await.result(repo.all(), 1 second).size should equal(2)
    }
  }

  describe("purge"){
    it("should clear all items"){
      repo.purge()
      Await.result(repo.all(), 1 second).size should equal(0)
    }
  }

}
 