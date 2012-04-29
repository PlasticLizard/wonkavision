package org.wonkavision.core

import org.scalatest.Spec
import org.scalatest.BeforeAndAfter
import org.scalatest.matchers.ShouldMatchers
import scala.io.Source
import org.wonkavision.core._
import AttributeType._

class AttributeSpec extends Spec with BeforeAndAfter with ShouldMatchers {

  val intAttr = Attribute("int", Integer)
  val decAttr = Attribute("dec", Decimal)
  val strAttr = Attribute("str", String)
  val timeAttr = Attribute("time", Time)
  val defAttr = Attribute("str", String, "haha!")
  
  before {
      
  }

  describe("coerce") {
    it ("should convert to Integer to Long") {
      intAttr.coerce("1") should equal (1L)
    }
    it ("should convert Decimal to Double") {
      decAttr.coerce("1.0") should equal (1.0)
    }
    it ("should convert String to ... a String") {
      strAttr.coerce(1.0) should equal ("1.0")
    }
    it ("should coerce Time to a DateTime") {
      timeAttr.coerce("2011-01-01") should equal (Convert.toDate("2011-01-01").get)
    }
  } 

  describe("ensure") {
    it ("should coerce a non-null value") {
      defAttr.ensure(1) should equal ("1")
    }
    it ("should return a default for a null value") {
      defAttr.ensure(null) should equal ("haha!")
    }
  }

  describe ("getDefault") {
    it ("should be 0 for integer") {
      intAttr.getDefault should equal (0)
    }
    it ("should be 0.0 for decimal") {
      decAttr.getDefault should equal (0.0)
    }
    it ("should be empty string for string") {
      strAttr.getDefault should equal("")
    }
    it ("should be null for time") {
      timeAttr.getDefault should equal(null)
    }
    it ("should use an explicit default if provided") {
      defAttr.getDefault should equal("haha!")
    }
  }

}
