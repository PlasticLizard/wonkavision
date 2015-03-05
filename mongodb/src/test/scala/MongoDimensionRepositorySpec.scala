package org.wonkavision.mongodb

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers

import org.wonkavision.core._
import org.wonkavision.core.DimensionMember
import org.wonkavision.server.messages._
import org.wonkavision.core.filtering._
import org.wonkavision.core.AttributeType._
import org.wonkavision.server.Wonkavision

import akka.actor.ActorSystem

class MongoDimensionRepositorySpec extends Spec with BeforeAndAfter with ShouldMatchers {
	
	implicit val cube = new Cube("hi")
	implicit val dim = Dimension("dim", Attribute("k", Integer), Attribute("c"))
  val system = ActorSystem("wonkavision")

	var memberData : List[DimensionMember] = _
  var repo : MongoDimensionRepository = _
 
  val filters = List(
    MemberFilterExpression.parse("dimension::dim::key::in::[1,2]"),
    MemberFilterExpression.parse("dimension::dim::caption::gte::b")
  )	

	before {
    memberData = List(
      dim.createMember(Map("k" -> 1, "c" -> "a")),
      dim.createMember(Map("k" -> 2, "c" -> "b")),
      dim.createMember(Map("k" -> 3, "c" -> "c"))
    ) 

    repo = new MongoDimensionRepository(dim, system)
    repo.purge()
    repo.put(memberData)
  }

  describe("select") {
    it("should return members with no filter specified") {
      val found = repo.select(new DimensionMemberQuery("hi", "dim", List()))
      found.size should equal(3)
    }
    it("should return the selected subset of members") {
      val found = repo.select(new DimensionMemberQuery("hi", "dim", filters))
      found.size should equal (1)
      found.head.key should equal (2)
    }  
    it("should select members without a key filter") {
      val found = repo.select(new DimensionMemberQuery("hi", "dim",filters.tail))
      found.size should equal (2)
      found.head.key should equal(2)
      found.last.key should equal(3)
    }  
    it("should select members with a single filter") {
      val f = List(MemberFilterExpression.parse("dimension::dim::key::eq::1"))
      val found = repo.select(new DimensionMemberQuery("hi", "dim", f))
      found.size should equal (1)
      found.head.key should equal(1)
    }
    it("should combine filters for the same key"){
      val f = List(MemberFilterExpression.parse("dimension::dim::caption::gte::b"),
                   MemberFilterExpression.parse("dimension::dim::caption::lte::c"))
      val found = repo.select(new DimensionMemberQuery("hi","dim",f))
      found.size should equal(2)
    }
  }

	describe("get") {
  	it("should return the selected member") {
  		repo.get(1).get.key should equal (1)    		
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
      repo.put(new DimensionMember(Map("k" -> 4, "c" -> "d")))
      repo.get(4).get.key should equal (4)
    }
    it ("should convert the key to the appropriate type"){
      repo.put(new DimensionMember(Map("k"->"4", "c"->"d")))
      repo.get(4).get.key should equal (4)
    }
  }

  describe("delete"){
    it ("should remove the specified member") {
      repo.get(1) should not equal(None)
      repo.delete(1)
      repo.get(1) should equal (None)
    }
  }

  describe("purge"){
    it("should clear all items"){
      repo.purge()
      repo.all().size should equal(0)
    }
  }

}
 