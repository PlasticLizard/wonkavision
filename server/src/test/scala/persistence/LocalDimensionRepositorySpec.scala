package org.wonkavision.server.persistence

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers

import org.wonkavision.core._
import org.wonkavision.server.DimensionMember
import org.wonkavision.server.messages._
import org.wonkavision.core.filtering._
import org.wonkavision.core.AttributeType._

class LocalDimensionRepositorySpec extends Spec with BeforeAndAfter with ShouldMatchers {
	
	implicit val cube = new Cube("hi")
	implicit val dim = Dimension("dim", Attribute("k", Integer), Attribute("c"))

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

    repo = new LocalDimensionRepository(dim, memberData)
  }

	describe("get") {
  	it("should return the selected member") {
  		repo.get("1").get.key should equal (1)    		
  	}  
  	it ("should return the selected") {
  		repo.get(1).get.key should equal (1)
  		repo.get(2).get.key should equal (2)
  		repo.get(3).get.key should equal (3)
  	}  
  	it ("should return none if not found") {
  		repo.get(4) should equal (None)
  	}
	}

	describe("all") {
		it ("should return the converted members") {
			val members = repo.all.toSeq
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
      repo.put(4, new DimensionMember(Map("k" -> 4, "c" -> "d")))
      repo.get(4).get.key should equal (4)
    }
    it ("should convert the key to the appropriate type"){
      repo.put("4", new DimensionMember(Map("k"->"4", "c"->"d")))
      repo.get(4).get.key should equal (4)
    }
  }

  describe("delete"){
    it ("should remove the specified member") {
      repo.get(1) should not equal(None)
      repo.delete(1)
      repo.get(1) should equal (None)
      repo.all().size should equal(2)
    }
  }

  describe("purge"){
    it("should clear all items"){
      repo.purge()
      repo.all().size should equal(0)
    }
  }

}
 