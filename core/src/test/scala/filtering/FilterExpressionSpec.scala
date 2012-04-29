package org.wonkavision.core.filtering

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import FilterOperator._
import org.scala_tools.time.Imports._
import Ordering.Implicits._

class FilterExpressionSpec extends Spec with BeforeAndAfter with ShouldMatchers {
  
  before {
  }
 
  describe("toString") {

    it ("should represent a single value without brackets") {
      new FilterExpression(Gt, Some(1)) should equal ("gt::1")
      new FilterExpression(Gt, List(1)) should equal ("gt::1")
    }

    it ("should represent a list using ruby array syntax") {
      new FilterExpression(Gt, List(1,2,3)) should equal ("gt::[1,2,3]")
    }

    it ("should use array syntax with In and Nin") {
      new FilterExpression(In, Some(1)) should equal ("in::[1]")
      new FilterExpression(Nin, Some(1)) should equal ("nin::[1]")
    }

    it ("should not delimit strings") {
      new FilterExpression(Eq, Some("1")) should equal ("eq::1")
    }

    it ("should delimit time with time()") {
      val now = DateTime.now
      new FilterExpression(Gt, Some(now)) should equal ("gt::time(" + now + ")")
    }

    it ("should not delimit an integer") {
      new FilterExpression(Eq, Some(1)) should equal ("eq::1")
    }

    it ("should not delimit a decimal number") {
      new FilterExpression(Eq, Some(1.0)) should equal ("eq::1.0")
    }
  }  

  describe ("matches") {
    it ("should evaluate Gt") {
      val gt1 = new FilterExpression(Gt, List(1))
      gt1.matches(2) should equal (true)
      gt1.matches(1) should equal (false)
      gt1.matches(0) should equal (false)
    }    
    it ("should evaluate Gte") {
      val gte1 = new FilterExpression(Gte, List(1))
      gte1.matches(2) should equal (true)
      gte1.matches(1) should equal (true)
      gte1.matches(0) should equal (false)
    }
    it ("should evalute Lt") {
      val lt1 = new FilterExpression(Lt, List(1))
      lt1.matches(2) should equal (false)
      lt1.matches(1) should equal (false)
      lt1.matches(0) should equal (true)
    }
    it ("should evalute Lte") {
      val lte1 = new FilterExpression(Lte, List(1))
      lte1.matches(2) should equal (false)
      lte1.matches(1) should equal (true)
      lte1.matches(0) should equal (true)
    }
    it ("should evaluate Eq") {
      val eq = new FilterExpression(Eq, List(1))
      eq.matches(2) should equal (false)
      eq.matches(1) should equal (true)
      eq.matches(0) should equal (false)
    }
    it ("should evaluate Ne") {
      val ne = new FilterExpression(Ne, List(1))
      ne.matches(2) should equal (true)
      ne.matches(1) should equal (false)
      ne.matches(0) should equal (true)
    }
    it ("should evaluate In") {
      val in = new FilterExpression(In, List(0,1,3,9))
      in.matches(2) should equal (false)
      in.matches(1) should equal (true)
      in.matches(0) should equal (true)
    }
    it ("should evaluate Nin") {
      val nin = new FilterExpression(Nin, List(0,1,3,9))
      nin.matches(2) should equal (true)
      nin.matches(1) should equal (false)
      nin.matches(0) should equal (false)
    }
  } 

}
