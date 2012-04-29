package org.wonkavision.core

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import scala.io.Source

class UtilSpec extends Spec with BeforeAndAfter with ShouldMatchers {

  before {
    
  }

  describe("combine") {
    it ("should produce a list of each possible combination") {
      Util.combine(List(1,2,3)) should equal (Seq(List(1), List(2), List(3), List(1, 2), List(1, 3), List(2, 3), List(1, 2, 3)))
    }    
  }

  describe("product") {
    it ("should produce a cartesian product of the provided lists") {
      Util.product(List(List(1,2,3),List(4,5),List(6,7,8,9))) should equal (
        List(
          List(1, 4, 6),
          List(1, 4, 7),
          List(1, 4, 8),
          List(1, 4, 9),
          List(1, 5, 6),
          List(1, 5, 7),
          List(1, 5, 8),
          List(1, 5, 9),
          List(2, 4, 6),
          List(2, 4, 7),
          List(2, 4, 8),
          List(2, 4, 9),
          List(2, 5, 6),
          List(2, 5, 7),
          List(2, 5, 8),
          List(2, 5, 9),
          List(3, 4, 6),
          List(3, 4, 7),
          List(3, 4, 8),
          List(3, 4, 9),
          List(3, 5, 6),
          List(3, 5, 7),
          List(3, 5, 8),
          List(3, 5, 9)) 
      )
    }

    it ("should be able to handle big products without stack overflow") {
      val dims = List((1 to 10).toList, (1 to 20).toList, (1 to 30).toList, (1 to 40).toList)
      Util.product(dims).size should equal (10 * 20 * 30 * 40)
    }
  }


}
