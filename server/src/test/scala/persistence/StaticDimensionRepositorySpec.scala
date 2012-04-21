package org.wonkavision.server.persistence

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers

import org.wonkavision.core._
import org.wonkavision.server.DimensionMember
import org.wonkavision.server.messages._
import org.wonkavision.core.filtering._
import org.wonkavision.core.AttributeType._

class StaticDimensionRepositorySpec extends Spec with BeforeAndAfter with ShouldMatchers {
	
	implicit val cube = new Cube("hi")
	implicit val dim = Dimension("dim", Attribute("k", Integer), Attribute("c"))

	val memberData = List(
		Map("k" -> 1, "c" -> "a"),
		Map("k" -> 2, "c" -> "b"),
		Map("k" -> 3, "c" -> "c")
	)	

	val filters = List(
		MemberFilterExpression.parse("dimension::dim::key::in::[1,2]"),
		MemberFilterExpression.parse("dimension::dim::caption::gte::b")
	)

	val repo = new StaticDimensionRepository(dim, memberData)

	before {}

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



}
 