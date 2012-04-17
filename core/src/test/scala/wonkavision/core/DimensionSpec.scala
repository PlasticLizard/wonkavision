package org.wonkavision.core

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import scala.io.Source
import org.wonkavision.core._

class DimensionSpec extends Spec with BeforeAndAfter with ShouldMatchers {

  var dim : Dimension = _

  before {
    dim = Dimension (
      name = "dimname",
      key = "dimkey",
      caption = "dimcap",
      sort = "dimsort"
    )
  }

  describe("Instantiation") {
    it("should create a new Dimension") {
      dim should equal (
        Dimension("dimname","dimkey","dimcap","dimsort")
      )
    }    
  }

}
