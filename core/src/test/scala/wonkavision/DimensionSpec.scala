package org.wonkavision.core

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import scala.io.Source
import org.wonkavision.core._

class DimensionSpec extends Spec with BeforeAndAfter with ShouldMatchers {

  var dim : Dimension = _
  var noattr : Dimension = _

  before {
    dim = Dimension (
      name = "dimname",
      key = Attribute("dimkey"),
      caption = Attribute("dimcap"),
      sort = Attribute("dimsort")
    )

    noattr = Dimension(name="dimname")

  }

  describe("Instantiation") {
    it("should create a new Dimension") {
      dim should equal (
        Dimension("dimname",Attribute("dimkey"),Attribute("dimcap"),Attribute("dimsort"))
      )
    }    
  }

  describe("Get attribute") {
    it ("should return the requested attribute") {
      dim.getAttribute("key").name should equal("dimkey")
      dim.getAttribute("caption").name should equal ("dimcap")
      dim.getAttribute("sort").name should equal ("dimsort")
    }
    it ("should fallback to other attributes if not provided") {
      noattr.getAttribute("key").name should equal("dimname")
      noattr.getAttribute("caption").name should equal ("dimname")
      noattr.getAttribute("sort").name should equal ("dimname")
    }
  }

}
