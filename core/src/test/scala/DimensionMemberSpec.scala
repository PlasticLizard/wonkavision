package org.wonkavision.core

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import org.wonkavision.core._
import org.wonkavision.core.filtering.MemberFilterExpression
import AttributeType._

class DimensionMemberSpec extends Spec with BeforeAndAfter with ShouldMatchers {

  implicit val cube = new Cube("hi")

  val attrMap = Map("k" -> "1", "c" -> "hi", "s" -> "1000")
  implicit val dim = Dimension(
    "mydim",
     Some(Attribute("k",Integer)),
     Some(Attribute("c")),
     Some(Attribute("s",Decimal))
  )

  val member = new DimensionMember(attrMap)
  
  before {
    
  }

  describe("construction") {
    it("should convert the value map to a vector of values") {
      member.attributeValues should equal (Vector(1,"hi",1000.0))
    }    
  }

  describe("apply") { 
    it("should fetch attribute values by name") {
      member("key").get should equal (1)
      member("caption").get should equal ("hi")
      member("sort").get should equal (1000.0)
    }
  }

  describe("at") {
    it("should fetch values by index") {
      member.at(0).get should equal(1)
      member.at(1).get should equal("hi")
      member.at(2).get should equal (1000.0)
    }
  }

  describe("matches"){
    it ("should match a filter") {
      var f = MemberFilterExpression.parse("dimension::mydim::key::lt::10")
      member.matches(f) should equal (true)
    }
    it ("shoult not match a filter") {
      var f = MemberFilterExpression.parse("dimension::mydim::key::gt::10")
      member.matches(f) should equal (false)
    }
    it ("should be true if all filters are true"){
      var f = List(
        MemberFilterExpression.parse("dimension::mydim::key::lt::10"),
        MemberFilterExpression.parse("dimension::mydim::sort::gt::100")
      )
      member.matches(f) should equal (true)
    }
    it ("should be false if any filters are false") {
      var f = List(
         MemberFilterExpression.parse("dimension::mydim::key::lt::10"),
        MemberFilterExpression.parse("dimension::mydim::sort::lt::100")
      )
      member.matches(f) should equal (false)
    }
  }

}
